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


## ⚠️ Beta Notice

This project is in active development. Currently, we only support the **OP Sepolia testnet**.

# Why EVMPack?

Let's be honest. Building on Ethereum can be a pain. We have amazing tools like Hardhat and Foundry, but they mostly help us with the first part of the journey: writing and testing our code. What happens after you deploy? That's when things get really hairy.

## The Deployment Hangover

Once your code is live, you're in a constant state of low-key anxiety. Did you introduce a bug in the latest upgrade? Did you accidentally specify the wrong implementation address? Broken storage?

This isn't a sustainable way to build an ecosystem. We're spending too much time and money on audits, reinventing the wheel with the same boilerplate code, and struggling to find reusable components we can actually trust.

## It's Time for a Better Way

EVMPack is our answer to this problem. It's not here to replace the tools you already love. It's here to make the entire lifecycle of your smart contracts safer, saner, and more collaborative.

With EVMPack, you can:

*   **Stop reinventing the wheel:** Find and use audited, reusable components for common tasks like user management or access control.
*   **Upgrade with confidence:** Our versioning system and secure deployment process are designed to protect you from shooting yourself in the foot.
*   **Focus on what you do best:** Build that one thing you're passionate about, and let EVMPack handle the rest.

## Let's Make Blockchain Development Fun Again

Ultimately, this is what it's all about. We believe that building on the blockchain should be a creative and joyful experience. It should be about bringing your ideas to life, not fighting with the limitations of the technology.

EVMPack is our attempt to get back to that feeling. It's about reducing the friction, increasing the velocity, and giving you the confidence to build the next generation of decentralized applications.

Let's build something amazing together.