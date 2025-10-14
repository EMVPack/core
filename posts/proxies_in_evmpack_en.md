# Proxy Contracts: A Comparison of OpenZeppelin and EVMPack Approaches

Upgrading smart contracts in mainnet is a non-trivial task. Deployed code is immutable, and any bug or need to add functionality requires complex and risky migrations. To solve this problem, the "proxy" pattern is used, which allows updating the contract's logic while preserving its address and state.

## What is a proxy contract?

A proxy contract is essentially an "empty" wrapper with a crucial detail - a custom `fallback` function. This function is a fundamental part of the EVM; it's automatically triggered when someone makes a call to the contract that doesn't match any of the explicitly declared functions.

This is where all the magic happens. When you call, for example, `myFunction()` on the proxy's address, the EVM doesn't find that function in the proxy itself. The `fallback` is triggered. Inside this function is low-level code (inline assembly) that takes all your call data (`calldata`) and forwards it using `delegatecall` to the "logic" contract's address.

The key feature of `delegatecall` is that the logic contract's code is executed, but all state changes (`storage`) occur within the context of the proxy contract. Thus, the proxy holds the data, and the logic contract holds the code. To upgrade, you just need to provide the proxy with a new implementation address.

## The Classic Approach: Hardhat + OpenZeppelin

The most popular development stack is Hardhat combined with OpenZeppelin's plugins. The `hardhat-upgrades` plugin significantly simplifies working with proxies by abstracting away the manual deployment of all necessary components.

Let's look at the actual code from a test for the `Blog` contract.

### Example 1: A Client-Managed Process

Here is what deploying a proxy looks like using the plugin in a JavaScript test:

```javascript
// test/Blog.js

const { upgrades, ethers } = require("hardhat");

// ...

describe("Blog", function () {
  it("deploys a proxy and upgrades it", async function () {
    const [owner] = await ethers.getSigners();

    // 1. Get the contract factory
    const Blog = await ethers.getContractFactory("Blog");

    // 2. Deploy the proxy. The plugin itself will:
    //    - deploy the Blog.sol logic contract
    //    - deploy the ProxyAdmin contract
    //    - deploy the proxy and link everything together
    const instance = await upgrades.deployProxy(Blog, [owner.address]);
    await instance.deployed();

    // ... checks go here ...

    // 3. Upgrade to the second version
    const BlogV2 = await ethers.getContractFactory("BlogV2");
    const upgraded = await upgrades.upgradeProxy(instance.address, BlogV2);

    // ... and more checks ...
  });
});
```

This solution is convenient, but its fundamental characteristic is that all the orchestration logic resides on the client side, in JavaScript. Executing the script initiates a series of transactions. This approach is well-suited for administration or development, but not for enabling other users or smart contracts to create instances of the contract.

## The On-Chain Approach: EVMPack

EVMPack moves the orchestration logic on-chain, acting as an on-chain package manager, similar to npm or pip.

### Example 2: The On-Chain Factory EVMPack

Suppose the developer of `Blog` has registered their package in EVMPack under the name `"my-blog"`. Any user or another smart contract can create an instance of the blog in a single transaction through the `EVMPackProxyFactory`:

```solidity
// Calling one function in the EVMPackProxyFactory contract

// EVMPackProxyFactory factory = EVMPackProxyFactory(0x...);

address myBlogProxy = factory.usePackageRelease(
    "my-blog",       // 1. Package name
    "1.0.0",         // 2. Required version
    msg.sender,      // 3. The owner's address
    initData,        // 4. Initialization data
    "my-first-blog" // 5. Salt for a predictable address
);

// The myBlogProxy variable now holds the address of a ready-to-use proxy.
// The factory has automatically created the proxy, its admin, and linked them to the logic.
```

It's important to understand that `usePackageRelease` can be called not just from another contract. Imagine a web interface (dApp) where a user clicks a "Create my blog" button. Your JavaScript client, using ethers.js, makes a single transaction - a call to this function. As a result, the user instantly gets a ready-made "application" on the blockchain side - their personal, upgradeable contract instance. Moreover, this is very gas-efficient, as only a lightweight proxy contract (and optionally its admin) is deployed each time, not the entire heavyweight implementation logic. Yes, the task of rendering a UI for it remains, but that's another story. The main thing is that we have laid a powerful and flexible foundation.

The process that was previously in a JS script is now on-chain, standardized, and accessible to all network participants.

## Comparison of Approaches

| Criterion | Hardhat + OpenZeppelin | EVMPack |
| :--- | :--- | :--- |
| **Where is the logic?** | **On the client** (in a JS script). | **On-chain** (in a factory contract). |
| **Who can call?**| Someone with the script and dependencies. | Any user or smart contract. |
| **Code Discovery** | Off-chain. You need to know which contract to deploy. | By name and version (`"my-blog@1.0.0"`). |
| **Deployment Process** | A series of transactions from the client. | Atomic. A single on-chain transaction. |
| **Isolation** | One `ProxyAdmin` can manage many proxies. | The factory creates a separate admin for each proxy. |
| **Philosophy** | A tool for the developer. | A public on-chain infrastructure. |

### How to Upgrade?

The upgrade process is just as simple, but designed more cleverly than one might assume. The proxy owner calls the `upgradeAndCall` function on their personal `EVMPackProxyAdmin` contract (which the factory created for them automatically).

This admin contract does not interact with the EVMPack registry directly. Instead, it commands the proxy contract itself to upgrade to the specified version.

```solidity
// Let's say the developer of "my-blog" has released version 1.1.0
// The proxy owner calls the function on their EVMPackProxyAdmin contract

IEVMPackProxyAdmin admin = IEVMPackProxyAdmin(myBlogProxyAdminAddress);

// The owner specifies which proxy contract to upgrade,
// to what version, and optionally passes data to call
// an initialization function on the new version.
admin.upgradeAndCall(
    IEVMPackProxy(myBlogProxyAddress), // Our proxy's address
    "1.1.0",                           // The new version from the registry
    ""                                 // Call data (empty string if not needed)
);

// Done! The proxy itself, knowing its package name, will contact the EVMPack registry,
// check the new version, get the implementation address, and upgrade itself.
// The contract's state is preserved.
```

As with creation, the process is entirely on-chain, secure (callable only by the owner), and does not require running any external scripts.

This architecture also provides significant security advantages. Firstly, there is a clear separation of roles: a simple admin contract is responsible only for authorizing the upgrade, which minimizes its attack surface. Secondly, since the proxy itself knows its package name and looks for the implementation by version, it protects the owner from accidental or malicious errors - it's impossible to upgrade the proxy to an implementation from a different, incompatible package. The owner operates with understandable versions, not raw addresses, which reduces the risk of human error.

### Advantages of an On-Chain Factory

The EVMPack approach transforms proxy creation into a public, composable on-chain service. This opens up new possibilities:

-   **DeFi protocols** that allow users to create their own isolated, upgradeable vaults.
-   **DAOs** that can automatically deploy new versions of their products based on voting results.
-   **NFT projects** where each NFT is a proxy leading to customizable logic.

This makes on-chain code truly reusable, analogous to npm packages.

## Conclusion

The `hardhat-upgrades` plugin is an effective tool that solves the problem for the developer.

EVMPack offers a higher level of abstraction, moving the process to the blockchain and creating a public service from it. This is not just about managing proxies; it's an infrastructure for the next generation of decentralized applications focused on composability and interoperability between contracts.
