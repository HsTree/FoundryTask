

import {Script, console} from "forge-std/Script.sol";
import {MetaNodeStake} from "../src/MetaNodeStake.sol";
import {MetaNodeToken} from "../src/MetaNode.sol";
import {MetaNodeStake_v2} from "../src/MetaNodeStake_v2.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";


contract MetaNodeStakeScript is Script {
    string constant DEPLOYMENT_FILE = "./deployments/simple.json"; // 指定一个部署的地址

    function run() public{
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);

        vm.startBroadcast(deployerKey);

        MetaNodeStake stake = new MetaNodeStake();
        MetaNodeToken token = new MetaNodeToken();

        address contract_address = address(stake);

        bytes memory data = abi.encodeWithSignature(
            "initialize(address,uint256,uint256,uint256)",
            address(token), // 代币合约地址
            0,      // 开始区块
            999999, // 结束区块
            10      // 每区块产出代币数量
        );

        ERC1967Proxy proxy_address = new ERC1967Proxy(contract_address, data);

        console.log("V1 impl address", address(stake));
        console.log("proxy addresss" , address(proxy_address));

        // 保存部署信息
        string memory deploymentData = string(abi.encodePacked(
            '{"network": "', vm.toString(block.chainid),
            '", "deployer": "', vm.toString(deployer),
            '", "metaNodeStake": "', vm.toString(address(stake)),
            '", "token": "', vm.toString(address(token)),
            '", "proxy": "', vm.toString(address(proxy_address)),
            '", "timestamp": "', vm.toString(block.timestamp),
            '"}'
        ));
        vm.writeJson(deploymentData, DEPLOYMENT_FILE);

        vm.stopBroadcast();
    }
}