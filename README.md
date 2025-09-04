# EVMPack: Blockchain Project Lifecycle Management

![Version](https://img.shields.io/badge/version-1.0.0--beta.1-blue)
![License](https://img.shields.io/badge/license-MIT-green)

**EVMPack is an infrastructure project for the EVM that brings order and security to the lifecycle management of smart contracts. It combines a decentralized package registry with strong semantic versioning (SemVer 2.0.0), with a focus on securely updating implementations.**

---

## 🤔 Why EVMPack?

Building on Ethereum can be a challenge. We have great tools for development and testing, but the post-deployment world is a bit of a wild west. That's where EVMPack comes in. It's not a replacement for your favorite tools, but a complementary layer that brings order to the chaos.

Key benefits for security and reliability:
- **Transparent Versioning**: All available contract versions and their dependencies are recorded on-chain.
- **Controlled Deployment**: An integrated proxy factory ensures that new proxy contracts are created with predictable and verified implementations.
- **Decentralized Governance**: The right to publish new versions is strictly controlled by a list of maintainers.

> To learn more about the vision and passion behind EVMPack, check out our [**Motivation**](./MOTIVATION.md).

## ⚠️ Beta Notice

This project is in active development. Currently, we only support the **OP Sepolia testnet**.

## 🚀 Getting Started

### Installation

As of now, you need to clone this repository and link it locally:

```bash
git clone https://github.com/evmpack/evmpack.git
cd evmpack
npm install && npm link
```

You can then verify the installation:
```bash
evmpack status
```

### Future Installation (Coming Soon!)
```bash
npx evmpack status
```

## 🛠️ Usage & Commands

EVMPack is a powerful tool with a lot of features. Here's a quick rundown of what you can do:

| Command | Description |
|---|---|
| `init` | Start a new EVMPack project. |
| `install [package]` | Install a package from the registry. |
| `upgrade [package]` | Upgrade a package to a new version. |
| `register` | Register a new package and share it with the world. |
| `release` | Create a new release for one of your packages. |
| `auth` | Authenticate yourself with the registry. |
| `compile` | Compile your smart contracts. |
| `info [package]` | Get the lowdown on a specific package. |
| `link` | Link local packages for easy development. |
| `list` | List all available packages. |
| `status` | Get a quick overview of your EVMPack setup. |
| `enable-node-support` | Hook up EVMPack with your Node.js projects. |
| `enable-foundry-support`| Hook up EVMPack with your Foundry projects. |
| `generate-release-note` | Let Gemini write your release notes for you. |
| `init-from-npm [package]`| Create an `evmpack.json` file from an NPM package. |


## 🗺️ The Road Ahead

We're just getting started! We have a lot of exciting ideas for the future of EVMPack, including a deterministic static analysis system, project scaffolding, and an on-chain service registry.

> To see what we're building next, check out our [**Roadmap**](./ROADMAP.md).

## ⚙️ The Nitty-Gritty: Smart Contracts

EVMPack is powered by a suite of smart contracts that handle everything from package registration to secure upgrades. If you want to dive deep into the technical details, you can find more information in the `release_note.md` file.

## 🤝 Let's Build Together

We believe in the power of collaboration. If you have an idea for how to make EVMPack better, we'd love to hear from you. Feel free to open an issue or submit a pull request.

---

### About

*   **Author**: Mikhail Ivantsov
*   **License**: MIT
*   **GitHub**: [https://github.com/evmpack](https://github.com/evmpack)
*   **X.com**: [https://x.com/darkraintech](https://x.com/darkraintech)
*   **Donation**: `0x602A44E855777E8b15597F0cDf476BEbB7aa70dE`
