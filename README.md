# Blockchain Project Lifecycle Management

EVMPack is an infrastructure project for the EVM that brings order and security to the lifecycle management of smart contracts. It combines a decentralized package registry with strong semantic versioning (SemVer 2.0.0), with a focus on securely updating implementations.

Key benefits for security and reliability:
- Transparent versioning: All available contract versions and their dependencies are recorded on-chain.
- Controlled deployment: An integrated proxy factory ensures that new proxy contracts are created with predictable and verified implementations.
- Decentralized governance: The right to publish new versions is strictly controlled by a list of maintainers. EVMPack is not just a dependency manager, but a framework for building fault-tolerant and easily maintainable decentralized systems.

## Why EVMPack?

Building on Ethereum can be a challenge. We have great tools for development and testing, but the post - deployment world is a bit of a wild west. That's where EVMPack comes in. It's not a replacement for your favorite tools, but a complementary layer that brings order to the chaos.

To learn more about the vision and passion behind EVMPack, check out our [**Motivation**](./MOTIVATION.md).

## Beta 

Currently this project in active development, now we support only op sepolia testnet. 

## Installation
In feature!
Getting started is easy. Just use the EVMPack CLI tool using npx:

```bash
npx evmpack status
```

But now clone this repo, and:

```bash
npm install && npm link && evmpack status
```

## What's Inside?

EVMPack is a powerful tool with a lot of features. Here's a quick rundown of what you can do:

| Command | Description |
|---|---|
| `enable-node-support` | Hook up EVMPack with your Node.js projects. |
| `enable-foundry-support` | Hook up EVMPack with your Foundry projects. |
| `generate-release-note` | Let Gemini write your release notes for you. |
| `status` | Get a quick overview of your EVMPack setup. |
| `register` | Register a new package and share it with the world. |
| `release` | Create a new release for one of your packages. |
| `init` | Start a new EVMPack project. |
| `install [package]` | Install a package from the registry. |
| `auth` | Authenticate yourself with the registry. |
| `compile` | Compile your smart contracts. |
| `upgrade [package]` | Upgrade a package to a new version. |
| `info [package]` | Get the lowdown on a specific package. |
| `link` | Link local packages for easy development. |
| `init-from-npm [package]` | Create an `evmpack.json` file from an NPM package. |

## The Road Ahead

We're just getting started! We have a lot of exciting ideas for the future of EVMPack, including a deterministic static analysis system, project scaffolding, and an on-chain service registry.

To see what we're building next, check out our [**Roadmap**](./ROADMAP.md).

## The Nitty-Gritty: Smart Contracts

EVMPack is powered by a suite of smart contracts that handle everything from package registration to secure upgrades. If you want to dive deep into the technical details, you can find more information in the `release_note.md` file.

## Let's Build Together

We believe in the power of collaboration. If you have an idea for how to make EVMPack better, we'd love to hear from you. Feel free to open an issue or submit a pull request.

---

*   **Author**: Mikhail Ivantsov
*   **License**: MIT
*   **Git**: [https://github.com/evmpack](https://github.com/evmpack)
*   **Homepage**: [https://github.com/evmpack](https://github.com/evmpack)
*   **Donation**: 0x602A44E855777E8b15597F0cDf476BEbB7aa70dE