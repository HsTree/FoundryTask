// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract SimpleV1 is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    uint256 public value;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(uint256 _value) public initializer {
        __Ownable_init(msg.sender);
        // 5.x 中 UUPS 初始化可能有所变化
        value = _value;
    }

    function setValue(uint256 _value) external onlyOwner {
        value = _value;
    }

    // 5.x 版本必须实现这个
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}