# The Road Ahead: Where We're Going with EVMPack

We're just getting started with EVMPack, and we've got a lot of exciting ideas for the future. This is our roadmap - a glimpse into what we're building next to make the Ethereum ecosystem even better.

## What We've Built So Far

Before we dive into the future, let's take a moment to appreciate how far we've come. We've already built a solid foundation for a more secure and collaborative Ethereum ecosystem. And all this in a week of development! 

*   **On-Chain Registry:** A decentralized registry for publishing and discovering smart contract packages.
*   **Robust Versioning:** A system for managing package versions based on the SemVer 2.0.0 standard.
*   **Secure, Versioned Proxies:** A set of transparent and upgradeable proxy contracts that are tightly integrated with our versioning system, making upgrades safer and more predictable.
*   **Powerful CLI:** An intuitive command-line interface that makes it easy to manage your packages and interact with the registry.
*   **IPFS Integration:** A seamless integration with IPFS for storing and retrieving package data.

This is the bedrock upon which we'll build the future of EVMPack.

## 0. Workspace

Now we can already use package implementations, it looks like this:

```bash

    $ evmpack use blog@1.1.0
    Using package: blog version: 1.1.0
    ✔ Enter your password to decrypt your private key:
    ✔ Enter EVMPack ProxyAdmin address (optional): 
    ✔ Enter a salt for CREATE2 (optional): example
    Please provide arguments for the initializer function: initialize(address)
    ✔ Enter value for '' (type: address): 0x5505957ff5927F29eAcaBbBE8A304968BF2dc064
    Proxy for blog@1.1.0 deployed at: 0x061968cCDC85e1be08fdAE15120A47C394d2000F with admin 0x59c6Fa34c02B1a54ef030c7D46A151B45081a3Cb

```

But now we need to remember all these addresses, make no mistakes, and, God forbid, lose them. Then we'll have to go to the explorer and extract our addresses from transactions. This is inconvenient, and we'll do everything we can to make it easy to work with implementations and eliminate the need to store addresses. Here's an example of how it will work.

```bash

$ evmpack workspace create
✔ Enter workspace name: Personal
Workspace create successfully!

$ evmpack workspace list
- Personal [ProxyAdmins:0, UsedPackages:0]

$ evmpack use blog@1.1.0
Using package: blog version: 1.1.0
✔ Enter your password to decrypt your private key:
✔ Select workspace: Personal
✔ Enter name app: My blog
✔ Select EVMPack ProxyAdmin (optional): 
✔ Enter a salt for CREATE2 (optional): example
Please provide arguments for the initializer function: initialize(address owner)
✔ Select value for 'owner' (account): Me

You have successfully started using package blog@1.1.0, named it "My blog" and stored in Personal workspace

$ evmpack workspace list
- Personal [ProxyAdmins:1, Apps:1]

$ evmpack workspace Personal --apps
| Name    | Package    | Admin         |
| My blog | blog@1.1.0 | PersonalAdmin |

$ evmpack workspace Personal --admins

| Name          | Apps                 |
| PersonalAdmin | My blog - blog@1.1.0 |

$ evmpack workspace Personal --checkupdates
| Name    | Package    | Latest version |
| My blog | blog@1.1.0 | 1.1.5          |

$ evmpack workspace Personal --update
✔ Select apps: My blog

My blog updated from blog@1.1.0 -> blog@1.1.5 success!


```

## 1. Security

### 1.1 A Guardian Angel for Your Code: Deterministic Static Analysis

Wouldn't it be great if you had a guardian angel watching over your code, catching potential security issues before they ever make it to production? That's what we're building with our deterministic static analysis system.

We're talking about a tool that will automatically scan your code for common vulnerabilities and best practice violations. It will be a mandatory step in the release process, so you can have peace of mind knowing that your code has been checked.

But it's only first step for security and hand audit.

### 1.2 Economic guarantee of security

In the blockchain world, a vulnerability can have major consequences. Users and investors don't know whether to trust an audit report, and not everyone is familiar with even the top auditing companies. No one wants to trust a PDF file.

**How will this work in our world?**

A package that wants to be trusted must provide a security deposit. The developer can deposit any amount themselves or pay a company that will cover the package with its security deposit after the audit.

Users will see the amount of the package's insurance and decide whether to use it.

The security deposit will be managed entirely by the DAO, meaning the deposit cannot be returned to the owner. In the event of an insured event, the deposit can be used to compensate for losses.

The ratio of the assets managed by the package to the deposit can be displayed and a rating can be generated.


## 2. UI

Each contract has its own ABI, and it's designed for program-to-program interaction. For each contract, we must develop a design, then layout it, debug it, and so on.

This is a very tedious and cost-inefficient process, and most contracts have the same type of user interaction:
- list objects,
- display object information,
- add object,
- update object,
- delete object

For all this, we can create an easily configurable, unified interface similar to an ABI, let's call it a UPI (User Programming Interface), but one designed for building programs that will interact with users. We just need to standardize the data structure that the generators will rely on.

Generators can generate user UIs on the fly with each new version, and we'll forget about ABI and UI compatibility forever.

## 3. Manager of documentation

Convenient management of all documentation, writing documentation using AI, checking documentation for compliance with changes before publishing a release


## 4. The App Store for Smart Contracts and them deploed implementations: A Curated Catalog

Finding high-quality, audited smart contracts shouldn't be a treasure hunt. We're building a curated catalog that will be like an app store for smart contracts.

You'll be able to browse, search, and filter packages, read reviews from the community, and find the perfect components for your next project. It's all about making it easier to stand on the shoulders of giants. You need ready and safety of implementation some Paymaster? Just select what you want and use it, when new version will come, you will be notify and you can upgrade safety, because you can see how many other contracts switch to new version and check audit insurance rating.

## 5. Bridging the Gap: The On-Chain Service Registry

It's time to bring the on-chain and off-chain worlds closer together. We're creating a decentralized marketplace for web2 services that you can access directly from your smart contracts.

Need to send an SMS, store a file on IPFS, or get some data from an API? You'll be able to find a provider in our on-chain service registry. It's all about making it easier to build powerful applications that connect to the real world.

## 8. Audit code

When we create first stable release we try to use this grant - https://atlas.optimism.io/missions/audit-grants 


## 9. Deploy mainnet
For main network we will be use optimism, but in the same time we deploy in all EVM networks. All  packages will be stored on optimistic network, and for implementations you can select one or more networks for register. Implementations will be with deterministic address

# P.S

This is just a taste of what's to come. We're always open to new ideas, so if you have a suggestion for how we can make EVMPack even better, we'd love to hear from you! Create a new issue with your idea!
