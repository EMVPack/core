# Add new release

Last time, we created a Blog package with an implementation type, but we completely forgot about tests. This package is clearly lacking functionality, the contract is meaningless from a real-world perspective. 

Let's add new methods: 
- addPostWithTags(), 
- updatePost(), 
- getPostTags(), 
- getPostsByTag(), 
- getPosts(), 
- getPostsCount()


New data structures, events, errors, storage variables:

```solidity
    // Appended for new features in v2 to avoid storage collision
    mapping(uint256 => string[]) private _postTags;
    mapping(string => uint256[]) private _postsByTag;

    event PostAdded(uint256 indexed postId, address indexed author, string[] tags);
    event PostUpdated(uint256 indexed postId);

    struct PostInfo {
        uint256 id;
        string content;
    }
```

Finish contract code:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@evmpack/contracts-upgrade@openzeppelin-5.4.0/proxy/utils/Initializable.sol";
import "@evmpack/contracts-upgrade@openzeppelin-5.4.0/access/OwnableUpgradeable.sol";

contract Blog is Initializable, OwnableUpgradeable {


    uint256 _counter;

    mapping(uint256 id => string PostData) _posts;

    // Appended for new features in v2 to avoid storage collision
    mapping(uint256 => string[]) private _postTags;
    mapping(string => uint256[]) private _postsByTag;

    event PostAdded(uint256 indexed postId, address indexed author, string[] tags);
    event PostUpdated(uint256 indexed postId);

    error Blog__InvalidPageNumber();
    error Blog__PostDoesNotExist(uint256 postId);

    struct PostInfo {
        uint256 id;
        string content;
    }

    function initialize(address owner) public initializer {
        __Ownable_init(owner);
    }


    function getVersion() public pure returns(string memory){
        return "1.1";
    }

    function addPost(string calldata post) onlyOwner external {
        _counter++; 
        uint256 newPostId = _counter;
        _posts[newPostId] = post;
        emit PostAdded(newPostId, msg.sender, new string[](0));
    }

    function addPostWithTags(string calldata content, string[] calldata tags) onlyOwner external {
        _counter++;
        uint256 newPostId = _counter;
        _posts[newPostId] = content;

        for (uint256 i = 0; i < tags.length; i++) {
            _postTags[newPostId].push(tags[i]);
            _postsByTag[tags[i]].push(newPostId);
        }
        emit PostAdded(newPostId, msg.sender, tags);
    }

    function updatePost(uint256 postId, string calldata newContent) onlyOwner external {
        if (postId == 0 || postId > _counter) {
            revert Blog__PostDoesNotExist(postId);
        }
        _posts[postId] = newContent;
        emit PostUpdated(postId);
    }

    function getPost(uint256 index) public view returns(string memory){
        return _posts[index];
    }

    function getPostTags(uint256 postId) public view returns (string[] memory) {
        return _postTags[postId];
    }


    function getPostsByTag(string calldata tag, uint256 page) public view returns (PostInfo[] memory) {
        uint256 pageSize = 10;
        uint256[] storage postIds = _postsByTag[tag];
        uint256 totalPosts = postIds.length;

        if (page == 0) {
            revert Blog__InvalidPageNumber();
        }

        uint256 startIndex = (page - 1) * pageSize;

        if (startIndex >= totalPosts) {
            return new PostInfo[](0);
        }

        uint256 endIndex = startIndex + pageSize;
        if (endIndex > totalPosts) {
            endIndex = totalPosts;
        }

        uint256 resultSize = endIndex - startIndex;
        PostInfo[] memory results = new PostInfo[](resultSize);

        for (uint256 i = 0; i < resultSize; i++) {
            uint256 postId = postIds[startIndex + i];
            results[i] = PostInfo({id: postId, content: _posts[postId]});
        }

        return results;
    }

    function getPosts(uint256 page) public view returns(PostInfo[] memory) {
        uint256 pageSize = 10;
        uint256 totalPosts = _counter;
        
        if (page == 0) {
            revert Blog__InvalidPageNumber();
        }

        uint256 startIndex = (page - 1) * pageSize;
        
        if (startIndex >= totalPosts) {
            return new PostInfo[](0);
        }

        uint256 endIndex = startIndex + pageSize;
        if (endIndex > totalPosts) {
            endIndex = totalPosts;
        }

        uint256 resultSize = endIndex - startIndex;
        PostInfo[] memory results = new PostInfo[](resultSize);

        for (uint256 i = 0; i < resultSize; i++) {
            uint256 postId = startIndex + i + 1;
            results[i] = PostInfo({id: postId, content: _posts[postId]});
        }

        return results;
    }

    function getPostsCount() public view returns (uint256) {
        return _counter;
    }
}
```

Now we write tests, for test we will use forge:

```bash
$ forge install foundry-rs/forge-std && mkdir test 
```


Since we initialized forge, we need to move our contract to the src folder.

```bash
mkdir src && mv Blog.sol src/
```

And this ready tests file test/Blog.t.sol:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../src/Blog.sol";

contract BlogTest is Test, Blog {
    Blog blog;
    address testOwner = address(this);
    address notOwner = address(0xDEAD);

    function setUp() public {
        blog = new Blog();
        blog.initialize(testOwner);
    }

    function test_InitialOwner() public view {
        assertEq(blog.owner(), testOwner);
    }

    function test_AddPost() public {
        string memory postContent = "Hello World";

        // Check for the PostAdded event
        vm.expectEmit(true, true, false, true);
        emit PostAdded(1, testOwner, new string[](0));

        blog.addPost(postContent);

        assertEq(blog.getPostsCount(), 1);
        assertEq(blog.getPost(1), postContent);
    }

    function test_Revert_AddPost_NotOwner() public {
        vm.prank(notOwner);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", notOwner));
        blog.addPost("fail post");
    }

    function test_AddPostWithTags() public {
        string memory content = "Post with tags";
        string[] memory tags = new string[](2);
        tags[0] = "tech";
        tags[1] = "solidity";

        // Check for the PostAdded event
        vm.expectEmit(true, true, false, true);
        emit PostAdded(1, testOwner, tags);

        blog.addPostWithTags(content, tags);

        assertEq(blog.getPostsCount(), 1);
        assertEq(blog.getPost(1), content);
        
        string[] memory retrievedTags = blog.getPostTags(1);
        assertEq(retrievedTags.length, 2);
        assertEq(retrievedTags[0], "tech");
        assertEq(retrievedTags[1], "solidity");
    }

    function test_Revert_AddPostWithTags_NotOwner() public {
        vm.prank(notOwner);
        string[] memory tags = new string[](0);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", notOwner));
        blog.addPostWithTags("fail post", tags);
    }

    function test_GetPostsByTag_Pagination() public {
        // Add 12 posts with the tag "pagination"
        for (uint256 i = 1; i <= 12; i++) {
            string memory content = string.concat("Post ", vm.toString(i));
            string[] memory tags = new string[](1);
            tags[0] = "pagination";
            blog.addPostWithTags(content, tags);
        }
        
        // Add a post with a different tag to ensure it's not picked up
        string[] memory otherTags = new string[](1);
        otherTags[0] = "other";
        blog.addPostWithTags("other post", otherTags);


        // Get page 1
        PostInfo[] memory results1 = blog.getPostsByTag("pagination", 1);
        assertEq(results1.length, 10, "Page 1 results count should be 10");
        assertEq(results1[0].id, 1, "First ID on page 1 should be 1");
        assertEq(results1[9].id, 10, "Last ID on page 1 should be 10");
        assertEq(results1[0].content, "Post 1", "First post content on page 1 is incorrect");

        // Get page 2
        PostInfo[] memory results2 = blog.getPostsByTag("pagination", 2);
        assertEq(results2.length, 2, "Page 2 results count should be 2");
        assertEq(results2[0].id, 11, "First ID on page 2 should be 11");
        assertEq(results2[1].id, 12, "Last ID on page 2 should be 12");
        assertEq(results2[0].content, "Post 11", "First post content on page 2 is incorrect");

        // Get page 3 (empty)
        PostInfo[] memory results3 = blog.getPostsByTag("pagination", 3);
        assertEq(results3.length, 0, "Page 3 results count should be 0");
    }

    function test_Revert_GetPostsByTag_PageZero() public {
        vm.expectRevert(Blog__InvalidPageNumber.selector);
        blog.getPostsByTag("any-tag", 0);
    }

    function test_GetPosts_Pagination() public {
        // Add 12 posts
        for (uint256 i = 1; i <= 12; i++) {
            blog.addPost(string.concat("Post ", vm.toString(i)));
        }

        // Get page 1
        PostInfo[] memory results1 = blog.getPosts(1);
        assertEq(results1.length, 10);
        assertEq(results1[0].id, 1);
        assertEq(results1[9].id, 10);
        assertEq(results1[0].content, "Post 1");

        // Get page 2
        PostInfo[] memory results2 = blog.getPosts(2);
        assertEq(results2.length, 2);
        assertEq(results2[0].id, 11);
        assertEq(results2[1].id, 12);
    }

    function test_Revert_GetPosts_PageZero() public {
        vm.expectRevert(Blog__InvalidPageNumber.selector);
        blog.getPosts(0);
    }

    function test_UpdatePost() public {
        // 1. Add a post
        blog.addPost("Original Content");
        uint256 postId = 1;

        // 2. Update the post
        string memory newContent = "Updated Content";
        // checkTopic1: postId (indexed), checkData: false
        vm.expectEmit(true, false, false, false);
        emit PostUpdated(postId);
        blog.updatePost(postId, newContent);

        // 3. Verify the update
        assertEq(blog.getPost(postId), newContent);
    }

    function test_Revert_UpdatePost_NotOwner() public {
        // 1. Add a post
        blog.addPost("Original Content");
        uint256 postId = 1;

        // 2. Try to update as non-owner
        vm.prank(notOwner);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", notOwner));
        blog.updatePost(postId, "Malicious Content");
    }

    function test_Revert_UpdatePost_NonExistent() public {
        uint256 nonExistentPostId = 999;
        vm.expectRevert(abi.encodeWithSelector(Blog__PostDoesNotExist.selector, nonExistentPostId));
        blog.updatePost(nonExistentPostId, "Content for non-existent post");
    }
}

```

Run tests:

```bash
$ forge test
[⠊] Compiling...
[⠒] Compiling 2 files with Solc 0.8.30
[⠢] Solc 0.8.30 finished in 986.20ms
Compiler run successful!

Ran 12 tests for test/Blog.t.sol:BlogTest
[PASS] test_AddPost() (gas: 69604)
[PASS] test_AddPostWithTags() (gas: 244800)
[PASS] test_GetPostsByTag_Pagination() (gas: 1437019)
[PASS] test_GetPosts_Pagination() (gas: 433126)
[PASS] test_InitialOwner() (gas: 10289)
[PASS] test_Revert_AddPostWithTags_NotOwner() (gas: 15588)
[PASS] test_Revert_AddPost_NotOwner() (gas: 14845)
[PASS] test_Revert_GetPostsByTag_PageZero() (gas: 14118)
[PASS] test_Revert_GetPosts_PageZero() (gas: 13410)
[PASS] test_Revert_UpdatePost_NonExistent() (gas: 14385)
[PASS] test_Revert_UpdatePost_NotOwner() (gas: 64322)
[PASS] test_UpdatePost() (gas: 68747)
Suite result: ok. 12 passed; 0 failed; 0 skipped; finished in 3.44ms (5.63ms CPU time)

Ran 1 test suite in 10.92ms (3.44ms CPU time): 12 tests passed, 0 failed, 0 skipped (12 total tests)
```

Ready! Now we a ready prepare new release, just change version in release.json up to 1.1.0 and run:

```bash
$ evmpack release
✔ Enter your password to decrypt your private key:
Compiling contracts...
Executing: forge build --via-ir --evm-version prague --optimize --optimizer-runs 200 --no-metadata --use 0.8.28 -C ./ -o ./artifacts --root ./src -q --remappings  @evmpack=/home/darkrain/.evmpack/packages
Compilation finished successfully.
✔ Edit your release note:
✔ Enter the address of the deployed implementation contract (empty for deploy now): 
🔗 Implementation deployed: 0x9953d86c77251558A03981d2740C807F3db6A1C5
add implementation ver
Successfully added release 1.1.0 for package blog
Transaction hash: 0xfe2adb70f3c28c6071c91ebf0077fbde8459402899473d9cda74f0968ca59413
```

Then you can check package info:

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
  Version: 1.1.0

```
Nice!