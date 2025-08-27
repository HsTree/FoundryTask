// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./MetaNodeStake.sol";

contract MetaNodeStake_v2 is MetaNodeStake {

    event HelloEvent(string message);
    // 新增功能，比如 hello() 测试
    function hello() public returns(string memory) {
        emit HelloEvent("Hello V2");
        return "Hello, V2!";
    }
}
