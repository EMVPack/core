# Init new package

If you wanna create new package, just run

```bash
$ mkdir newpackage && cd newpackage && evmpack init
✔ Package name: blog
✔ Title: Blog for your app
✔ Description: Contract for manage blog posts
✔ Author: Vitalik
✔ Package type: implementation
✔ Main contract name (without .sol extension): Blog
✔ Selector: 
✔ License: MIT
✔ Solidity version: 0.8.28
✔ Git repository: 
✔ Homepage: 
✔ Tags (comma-separated): blog, posts, text

evmpack.json and release.json created successfully!

```

EVMPack create for you 2 files: 

```bash
    $ cat evmpack.json
    {
        "name": "blog",
        "type": "implementation",
        "title": "Blog for your app",
        "description": "Contract for manage blog posts",
        "author": "Vitalik",
        "license": "MIT",
        "git": "",
        "tags": [
            "blog",
            "posts",
            "text"
        ],
        "homepage": ""
    }
    
    $ cat release.json
    {
        "version": "1.0.0",
        "dependencies": {},
        "main_contract": "Blog",
        "selector": ""
    }
```

Everything here is standard for a package manager, except:

- evmpack.json:type - We've chosen the implementation package type, which means we'll not only download the source code, but also deploy the implementation so it can be used in other packages.
- release.json:selector - This parameter is important for the implementation package type, because we need to explicitly specify which method to call and with what parameters when initializing the implementation. If you don't understand, then don't bother your head, you'll understand later.

