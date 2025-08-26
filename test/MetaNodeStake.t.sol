pragma solidity ^0.8;
import {Test,console} from "forge-std/Test.sol";
import {MetaNodeToken} from "../src/MetaNode.sol";
import {MetaNodeStake} from "../src/MetaNodeStake.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

library UserAssert{
    function userAssertEq(address token, address user, uint256 amount) public{
        uint256 userBalance = ERC20(token).balanceOf(address(user));
        if (userBalance != amount) {
            revert(string(abi.encodePacked("UserAssert: balance not equal, expected ")));
        }
    }
}

contract MetaNodeStakeTest is Test{
    MetaNodeStake MetaNodeStakec;
    MetaNodeToken MetaNodeTokenc;

    using UserAssert for address;

    address admin_address = vm.addr(1);
    address user_address = vm.addr(2);

    event Withdraw(address indexed user, uint256 indexed poolId, uint256 amount, uint256 indexed blockNumber);
    event Deposit(address indexed user, uint256 indexed poolId, uint256 amount);

    fallback() external payable{
    }
    receive() external payable{
    }

    function setUp() public{
        // console.log(admin_address);
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

    function test_addPool1() public{
        test_addPool();
        address tokenAddress = address(MetaNodeTokenc);
        uint256 weight = 1;
        uint256 mindepositAmount = 1;
        uint256 lockBlock = 10;
        bool withUpdate = true;
        MetaNodeStakec.addPool(tokenAddress, weight, mindepositAmount, lockBlock, withUpdate);

        uint256 poolLenth = MetaNodeStakec.poolLength();
        assertGt(poolLenth, 1);
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
        // vm.assume(amount < 2 ether);  // 设置amount的范围 进行测试
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
        
        MetaNodeStakec.unstake(0, 7 ether);
        vm.roll(80000);
        MetaNodeStakec.withdraw(0);
        assertEq(userBalance - address(this).balance / (10**18), 0); // 检查一下 取出来的余额还对不对
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
        test_addPool();
        uint256 preTokenBalance = address(MetaNodeStakec).balance/(10**18);
        uint256 preUserBalance = address(this).balance/(10**18);
        
        test_transferEth(2 ether);
        vm.roll(10000);
        uint256 afterTokenBalance = address(MetaNodeStakec).balance/(10**18);
        uint256 afterUserBalance = address(this).balance/(10**18);
        
        assertEq(afterTokenBalance, preTokenBalance + 2);
        assertEq(afterUserBalance, preUserBalance - 2);

        // 需要先进行记录日志在进行转账 不然的话会报错
        // vm.expectEmit(true, false, false, true);
        // emit Withdraw(address(this), 0, 2 ether, 10000);

        MetaNodeStakec.unstake(0, 2 ether);

        // vm.prank(user_address);  // 切换用户
        vm.roll(20000);
        MetaNodeStakec.withdraw(0);
        
        uint256 finalUserBalance = address(this).balance/(10**18);
        vm.roll(30000);
        assertEq(finalUserBalance, preUserBalance); // 检查一下取款后跟存款钱的余额
    }
    
    function test_depositClaim() public {
        test_addPool1(); 
        MetaNodeTokenc.balanceOf(address(this));
        assertEq(MetaNodeTokenc.balanceOf(address(this)), 10000000000000000000000000);
        MetaNodeTokenc.approve(address(MetaNodeStakec), 100000000);  // 转账前先进行授权 否则会失败
        MetaNodeStakec.deposit(1, 100000000);
        assertEq(MetaNodeTokenc.balanceOf(address(this)), 10000000000000000000000000 - 100000000);

        (address stTokenAddress,
        uint256 poolWeight,
        uint256 lastRewardBlock,
        uint256 accMetaNodePerST,
        uint256 stTokenAmount,
        uint256 minDepositAmount,
        uint256 unstakeLockedBlocks) = MetaNodeStakec.pool(1);
        assertEq(stTokenAmount, 100000000);
        assertEq(stTokenAddress, address(MetaNodeTokenc));
        vm.roll(30000);
        MetaNodeStakec.claim(1);
        
        // uint256 amount = MetaNodeStakec.stakingBalance(1, address(this));
        // console.log("amount: ", amount);
        assertGt(MetaNodeTokenc.balanceOf(address(this)), 10000000000000000000000000 - 100000000); // 看看押质后的余额是否增加
    }

    function test_assertEq()public {  // 测试一下自定义的library功能的使用方法
        address(MetaNodeTokenc).userAssertEq(address(this), 10000000000000000000000001);
        // UserAssert.userAssertEq(address(MetaNodeTokenc), address(this), 10000000000000000000000001);
    }

}