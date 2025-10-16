# Use package implementation

Before we created powerful package - Blog. Now you and everybody can use, just run in every directory


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

## What happened here?

Here we're working with the **EVMPackProxyFactory** contract. It deploys a simple EVMPackProxy based on OpenZeppelin's TransparentUpgradeableProxy and binds the blog package implementation, version 1.1.0, and calls initialize.

Since we didn't specify the **EVMPackProxyAdmin** address, **EVMPackProxyAdmin** is created automatically, and we have two output addresses:

- **0x061968cCDC85e1be08fdAE15120A47C394d2000F** - the address of our proxy, which routes all requests to the blog package implementation, version 1.1.0, via delegatecall.
- **0x59c6Fa34c02B1a54ef030c7D46A151B45081a3Cb** - the address of the admin contract, it owns the proxy contract and can update it. We can use it when creating new proxy contracts.

It's convenient because you don't need to search for contract addresses or compile and deploy it yourself. If the developer releases a new version of the blog, you can easily update it.