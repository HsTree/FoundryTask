// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {SimpleV1} from "../src/SimpleV1.sol";
import {SimpleV2} from "../src/SimpleV2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

interface ISimple {
    function value() external view returns (uint256);
    function setValue(uint256 _v) external;
}

contract DeployAndUpgrade is Script {
    string constant DEPLOYMENT_FILE = "./deployments/simple.json";
    
    function run() external {
        uint256 deployerkey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerkey);
        vm.startBroadcast(deployerkey);

        // 1) 部署 V1 impl
        SimpleV1 implV1 = new SimpleV1();
        console.log("implV1:", address(implV1));

        // 2) 部署 proxy 并初始化
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implV1),
            abi.encodeWithSelector(SimpleV1.initialize.selector, 10)
        );
        console.log("proxy:", address(proxy));

        // 3) 测试调用
        ISimple(address(proxy)).setValue(100);
        console.log("value after setValue:", ISimple(address(proxy)).value());

        // 4) 部署 V2 impl
        SimpleV2 implV2 = new SimpleV2();
        console.log("implV2:", address(implV2));

        // 5) 升级 - 使用 5.x 版本的 upgradeToAndCall
        bytes memory upgradeCallData = abi.encodeWithSignature("initialize(uint256)", 0); // 如果需要初始化

        (bool success, ) = address(proxy).call(
            abi.encodeWithSignature(
                "upgradeToAndCall(address,bytes)", 
                address(implV2),
                ""
            )
        );
        require(success, "Upgrade failed");
        console.log("Upgrade successful");


        // 保存部署信息
        string memory deploymentData = string(abi.encodePacked(
            '{"network": "', vm.toString(block.chainid),
            '", "deployer": "', vm.toString(deployer),
            '", "implementationV1": "', vm.toString(address(implV1)),
            '", "implementationV2": "', vm.toString(address(implV2)),
            '", "proxy": "', vm.toString(address(proxy)),
            '", "timestamp": "', vm.toString(block.timestamp),
            '"}'
        ));

        vm.writeJson(deploymentData, DEPLOYMENT_FILE);

        vm.stopBroadcast();
    }
}