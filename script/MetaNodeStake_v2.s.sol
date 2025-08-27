

import {Script, console} from "forge-std/Script.sol";
import {MetaNodeStake} from "../src/MetaNodeStake.sol";
import {MetaNodeStake_v2} from "../src/MetaNodeStake_v2.sol";
import {MetaNodeToken} from "../src/MetaNode.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {stdJson} from "forge-std/StdJson.sol";


interface IProxy {
    function upgradeToAndCall(address newImplementation, bytes memory data) external;
    function owner() external view returns (address);
}

contract MetaNodeStakeScriptV2 is Script {
    string constant DEPLOYMENT_FILE = "./deployments/simple.json"; // 指定一个部署的地址
    using stdJson for string;
    function run() public{
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);

        // 读取部署文件
        address proxy_address = vm.readFile(DEPLOYMENT_FILE).readAddress(".proxy");

        // 使用 proxyAddress
        console.log("Proxy Address:", proxy_address);

        vm.startBroadcast(deployerKey);

        MetaNodeStake_v2 impl_v2 = new MetaNodeStake_v2();
        console.log("V2 impl:", address(impl_v2));

        IProxy(address(proxy_address)).upgradeToAndCall(address(impl_v2), "");

        // 测试调用 V2 新方法
        MetaNodeStake_v2 stakeV2 = MetaNodeStake_v2(address(proxy_address));
        console.log(stakeV2.hello());

        // 保存部署信息
        string memory deploymentData = string(abi.encodePacked(
            '{"network": "', vm.toString(block.chainid),
            '", "deployer": "', vm.toString(deployer),
            '", "metaNodeStake": "', vm.toString(address(impl_v2)),
            '", "proxy": "', vm.toString(address(proxy_address)),
            '", "timestamp": "', vm.toString(block.timestamp),
            '"}'
        ));
        vm.writeJson(deploymentData, DEPLOYMENT_FILE);

        vm.stopBroadcast();
    }
}