pragma solidity ^0.8;
import {Test,console} from "forge-std/Test.sol";
import {MetaNodeToken} from "../src/MetaNode.sol";
import {MetaNodeStake} from "../src/MetaNodeStake.sol";

contract MetaNodeStakeTest is Test{
    MetaNodeStake MetaNodeStakec;
    MetaNodeToken MetaNodeTokenc;
    address admin_address = vm.addr(1);

    fallback() external payable{
    }
    receive() external payable{
    }

    function setUp() public{
        console.log(admin_address);
        MetaNodeTokenc = new MetaNodeToken();
        MetaNodeStakec = new MetaNodeStake();
        MetaNodeStakec.initialize(MetaNodeTokenc, 0, 999999, 10);
    }

    function test_depolyAccount() public{
        bytes32 admin_role = MetaNodeStakec.ADMIN_ROLE();
        MetaNodeStakec.grantRole(admin_role, admin_address);
        bool result = MetaNodeStakec.hasRole(admin_role, admin_address);
        assertEq(result, true);
    }

    function test_addPool() public{
        address token_address = address(0x0);
        uint256 weight = 1;
        uint256 mindepositAmount = 1;
        uint256 lockBlock = 10;
        bool withUpdate = true;
        MetaNodeStakec.addPool(token_address, weight, mindepositAmount, lockBlock, withUpdate);

        uint256 poolLenth = MetaNodeStakec.poolLength();
        (address stTokenAddress,
        uint256 poolWeight,
        uint256 lastRewardBlock,
        uint256 accMetaNodePerST,
        uint256 stTokenAmount,
        uint256 minDepositAmount,
        uint256 unstakeLockedBlocks) = MetaNodeStakec.pool(0);
        assertEq(poolLenth, 1);
        assertEq(stTokenAddress, token_address);
    }

    function test_massUpdatePool() public{
        test_addPool();
        MetaNodeStakec.massUpdatePools();
        (address stTokenAddress,
        uint256 poolWeight,
        uint256 lastRewardBlock,
        uint256 accMetaNodePerST,
        uint256 stTokenAmount,
        uint256 minDepositAmount,
        uint256 unstakeLockedBlocks) = MetaNodeStakec.pool(0);
        assertEq(lastRewardBlock, 1);

        vm.roll(10000);
        MetaNodeStakec.massUpdatePools();
        (stTokenAddress,
         poolWeight,
         lastRewardBlock,
         accMetaNodePerST,
         stTokenAmount,
         minDepositAmount,
         unstakeLockedBlocks) = MetaNodeStakec.pool(0);
        assertEq(lastRewardBlock, 10000);
    }

    function test_setWeight() public{
        test_addPool();
        uint256 afterPoolWeight = MetaNodeStakec.totalPoolWeight();
        assertEq(afterPoolWeight, 1);
        MetaNodeStakec.setPoolWeight(0, 10, true);
        (address stTokenAddress,
        uint256 poolWeight,
        uint256 lastRewardBlock,
        uint256 accMetaNodePerST,
        uint256 stTokenAmount,
        uint256 minDepositAmount,
        uint256 unstakeLockedBlocks) = MetaNodeStakec.pool(0);
        assertEq(poolWeight, afterPoolWeight - 1 + 10);
    }

    function test_transferEth(uint256 amount) public{
        address(MetaNodeStakec).call{value:amount}(
            abi.encodeWithSignature("depositETH()")
        );
    }

    function test_deposit_currency()public{
        test_addPool();
        (address stTokenAddress,
        uint256 poolWeight,
        uint256 lastRewardBlock,
        uint256 accMetaNodePerST,
        uint256 stTokenAmount,
        uint256 minDepositAmount,
        uint256 unstakeLockedBlocks) = MetaNodeStakec.pool(0);

        uint256 userBalance = address(this).balance/ (10**18);
        test_transferEth(1 ether);
        (
          uint256 PreStAmount,
          uint256 PreFinishedMetaNode,
          uint256 PrePendingMetaNode
        ) = MetaNodeStakec.user(0, address(this));
        assertEq(PreStAmount, 1 ether);

        assertEq(userBalance-1, address(this).balance / (10**18)); // 检查一下 存进去后的余额是否正确
        
        vm.roll(10000);
        test_transferEth(2 ether);
        MetaNodeStakec.unstake(0, 1 ether);
        
        vm.roll(20000);
        test_transferEth(3 ether);
        MetaNodeStakec.unstake(0, 1 ether);

        vm.roll(30000);
        test_transferEth(4 ether);
        MetaNodeStakec.unstake(0, 1 ether);

        vm.roll(70000);
        (
          uint256 StAmount,
          uint256 FinishedMetaNode,
          uint256 PendingMetaNode
        ) = MetaNodeStakec.user(0, address(this));

        assertEq(StAmount, 7 ether); // 检查一下目前还在押质的数量有多少
        assertEq(userBalance-10, address(this).balance / (10**18)); // 检查一下 存进去后的余额是否正确
        
        MetaNodeStakec.withdraw(0);
        // assertEq(userBalance - address(this).balance / (10**18), 10); // 检查一下 取出来的余额还对不对
    }

    function test_UnStake() public{
        // test_deposit_currency();
        test_addPool();
        // vm.roll(800);
        // MetaNodeStakec.unstake(0, 1 ether);
        // vm.roll(900);
        (
          uint256 StAmount,
          uint256 FinishedMetaNode,
          uint256 PendingMetaNode
        ) = MetaNodeStakec.user(0, address(this));

        assertEq(StAmount, 0); 

        test_transferEth(5 ether);
        (
           StAmount,
           FinishedMetaNode,
           PendingMetaNode
        ) = MetaNodeStakec.user(0, address(this));
        assertEq(StAmount, 5 ether); 

        MetaNodeStakec.unstake(0, 2 ether);
                (
           StAmount,
           FinishedMetaNode,
           PendingMetaNode
        ) = MetaNodeStakec.user(0, address(this));
        assertEq(StAmount, 3 ether); 
    }

    function test_withdraw() public{
        test_UnStake();
        uint256 preTokenBalance = address(MetaNodeStakec).balance/(10**18);
        assertEq(preTokenBalance, 0);
    }
    

}