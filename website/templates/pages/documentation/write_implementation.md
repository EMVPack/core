# Write implementation contract 


For example you can paste this code of contract 

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@evmpack/contracts-upgrade@openzeppelin-5.4.0/proxy/utils/Initializable.sol";
import "@evmpack/contracts-upgrade@openzeppelin-5.4.0/access/OwnableUpgradeable.sol";

contract Blog is Initializable, OwnableUpgradeable {


    uint256 _counter;

    mapping(uint256 id => string PostData) _posts;

    function initialize(address owner) public initializer {
        __Ownable_init(owner);
    }

    function getVersion() public pure returns(string memory){
        return "1.0";
    }

    function addPost(string calldata post) onlyOwner external {
        _counter++; 
        _posts[_counter] = post;
    }

    function getPost(uint256 index) public view returns(string memory){
        return _posts[index];
    }

}
```

Now we are ready to compile, try to run:

```bash
$ evmpack compile
Executing: forge build --via-ir --evm-version prague --optimize --optimizer-runs 200 --no-metadata --use 0.8.28 -C ./ -o ./artifacts --root ./ --skip node_modules/* -q --remappings  @evmpack=/home/darkrain/.evmpack/packages
Compilation finished successfully.
```

Everything ok, but it's because we already installed foundry. If you don't install foundry before, then you will see this error message:

```bash
$ evmpack compile
Forge is not installed. Please install Foundry: https://book.getfoundry.sh/getting-started/installation
```

We are using forge because them compiler very fast!

After success compile you will be have new folder **artifacts/**