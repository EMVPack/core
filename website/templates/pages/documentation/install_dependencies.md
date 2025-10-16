# Install dependencies

First what you need for create implementation package, its contracts-upgrade@openzeppelin package:

```bash
$ evmpack install contracts-upgrade@openzeppelin

Resolving package contracts-upgrade@openzeppelin@latest...
Fetching release info for contracts-upgrade@openzeppelin@5.4.0...
Fetching release info for contracts@openzeppelin@5.4.0...
Locked contracts@openzeppelin@5.4.0.
Already installed: contracts@openzeppelin@5.4.0
Locked contracts-upgrade@openzeppelin@5.4.0.
Already installed: contracts-upgrade@openzeppelin@5.4.0
```

Now lets check release.json:

```bash
$ cat release.json

{
  "version": "1.0.0",
  "dependencies": {
    "contracts-upgrade@openzeppelin": "^5.4.0"
  },
  "main_contract": "Blog",
  "selector": ""
}
```
In dependencies block we are see our installed package **contracts-upgrade@openzeppelin** with version **^5.4.0**

And we have one new file:

```bash
$ cat evmpack-lock.json

{
  "lockfileVersion": 1,
  "packages": {
    "contracts-upgrade@openzeppelin@5.4.0": {
      "version": "5.4.0",
      "resolved": "QmSpN4HCpt3VSRHbP6KvRRa2kkfVfPk9EBN9fu39hF2d5f",
      "dependencies": [
        {
          "name": "contracts@openzeppelin",
          "version": "^5.4.0"
        }
      ]
    },
    "contracts@openzeppelin@5.4.0": {
      "version": "5.4.0",
      "resolved": "QmUk12bU4DWHAx6Jtqq1uWpuRn1qczHuZSVp8sv7JbBPjq",
      "dependencies": []
    }
  }
}
```

You may notice that two packages were actually downloaded. This is because the package **contracts-upgrade@openzeppelin@5.4.0** has a dependency on the package **contracts@openzeppelin@5.4.0.**

You can also see the IPFS hash of the tarball itself in resolved.

All packages located in **$HOME/.evmpack/packages**

Great, we've installed the packages and can now create our first contract.

