// script/ProxyStorageCheck.s.sol
pragma solidity ^0.8.22;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

contract ProxyStorageCheck is Script {
    address constant PROXY_ADDRESS = 0x7DF3B6cC27574e85a7F712f32Bb7a818EaE91EbF;
    
    // UUPS 代理的典型存储槽位
    bytes32 constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    bytes32 constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
    
    function run() external {
        console.log("Checking proxy storage directly...");
        
        // 读取实现地址存储槽
        address implementation;
        assembly {
            implementation := sload(IMPLEMENTATION_SLOT)
        }
        console.log("Implementation from storage: ", implementation);
        
        // 读取管理员地址存储槽
        address admin;
        assembly {
            admin := sload(ADMIN_SLOT)
        }
        console.log("Admin from storage: ", admin);
        
        // 检查当前实现合约的代码
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(implementation)
        }
        console.log("Implementation code size: ", codeSize, "bytes");
    }
}