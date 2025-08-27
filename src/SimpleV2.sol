// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./SimpleV1.sol";

contract SimpleV2 is SimpleV1 {
    // 新增函数
    function increment() external {
        value = value + 1;
    }

    // 覆盖: 仍使用 V1 的 _authorizeUpgrade（来自祖先）
}
