

import {Script, console} from "forge-std/Script.sol";
import {MetaNodeStake} from "../src/MetaNodeStake.sol";
import {MetaNodeToken} from "../src/MetaNode.sol";


contract MetaNodeStakeScript is Script {
    function run() public{
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        console.log(deployerKey);

        vm.startBroadcast(deployerKey);

        MetaNodeStake stake = new MetaNodeStake();
        
        vm.stopBroadcast();
        console.log(address(stake));
    }

}