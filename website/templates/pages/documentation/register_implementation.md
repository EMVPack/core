# Register implementation contract 

In first time you should register package, after that you will be create only releases for this package.

```bash
$ evmpack register
✔ Enter your password to decrypt your private key:
Starting package registration...
Compiling contracts...
Executing: forge build --via-ir --evm-version prague --optimize --optimizer-runs 200 --no-metadata --use 0.8.28 -C ./ -o ./artifacts --root ./ --skip node_modules/* -q --remappings  @evmpack=/home/darkrain/.evmpack/packages
Compilation finished successfully.
✔ Edit your release note:
✔ Enter the address of the deployed implementation contract (empty for deploy now):
🔗 Implementation deployed: 0xf... 
📝 Registration transaction sent: 0xba..
✅ Package registered successfully!

```

You can deploy your implementation before run this command and paste address when EVMPack ask you, but to be on the safe side it's better to leave it blank

Lets check our package:

```bash
$ evmpack info blog
Package: blog
Title: Blog for your app
Description: Contract for manage blog posts
Author: Vitalik
License: MIT
Type: implementation

Maintainers:
  Address: 0x5505957ff5927F29eAcaBbBE8A304968BF2dc064

Releases:
  Version: 1.0.0

```

We've created a package with the implementation type! We'll easily release an update next time.
