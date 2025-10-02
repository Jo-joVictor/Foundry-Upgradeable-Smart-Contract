// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {FundMeV1} from "../src/FundMeV1.sol";
import {FundMeV2} from "../src/FundMeV2.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract FundMeTest is Test {
    FundMeV1 public fundMeV1;
    FundMeV2 public fundMeV2;
    address public proxy;
    
    address public owner = makeAddr("owner");
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");
    address public user3 = makeAddr("user3");
    address public user4 = makeAddr("user4");
    address public user5 = makeAddr("user5");
    
    uint256 constant SEND_VALUE = 0.001 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    
    function setUp() public {
        // Fund test accounts
        vm.deal(owner, STARTING_BALANCE);
        vm.deal(user1, STARTING_BALANCE);
        vm.deal(user2, STARTING_BALANCE);
        vm.deal(user3, STARTING_BALANCE);
        vm.deal(user4, STARTING_BALANCE);
        vm.deal(user5, STARTING_BALANCE);
        
        // Deploy V1
        vm.startPrank(owner);
        FundMeV1 implementation = new FundMeV1();
        bytes memory data = abi.encodeWithSelector(FundMeV1.initialize.selector);
        proxy = address(new ERC1967Proxy(address(implementation), data));
        fundMeV1 = FundMeV1(payable(proxy));
        vm.stopPrank();
    }
    
    // ======== V1 Tests ========
    
    function testInitialization() public view {
        assertEq(fundMeV1.owner(), owner);
        assertEq(fundMeV1.version(), 1);
        assertEq(fundMeV1.getFundersCount(), 0);
    }
    
    function testFundWithEnoughETH() public {
        vm.prank(user1);
        fundMeV1.fund{value: SEND_VALUE}();
        
        assertEq(fundMeV1.getFundersCount(), 1);
        assertTrue(fundMeV1.hasFunded(user1));
        assertEq(address(fundMeV1).balance, SEND_VALUE);
    }
    
    function testFundFailsWithInsufficientETH() public {
        vm.prank(user1);
        vm.expectRevert("Minimum funding is 0.001 ETH");
        fundMeV1.fund{value: 0.0005 ether}();
    }
    
    function testMultipleFunders() public {
        vm.prank(user1);
        fundMeV1.fund{value: SEND_VALUE}();
        
        vm.prank(user2);
        fundMeV1.fund{value: SEND_VALUE}();
        
        vm.prank(user3);
        fundMeV1.fund{value: SEND_VALUE}();
        
        assertEq(fundMeV1.getFundersCount(), 3);
        assertEq(address(fundMeV1).balance, SEND_VALUE * 3);
    }
    
    function testSameFunderMultipleTimes() public {
        vm.startPrank(user1);
        fundMeV1.fund{value: SEND_VALUE}();
        fundMeV1.fund{value: SEND_VALUE}();
        vm.stopPrank();
        
        // Should only count as 1 funder
        assertEq(fundMeV1.getFundersCount(), 1);
        assertEq(address(fundMeV1).balance, SEND_VALUE * 2);
    }
    
    function testWithdrawFailsBeforeGoal() public {
        vm.prank(user1);
        fundMeV1.fund{value: SEND_VALUE}();
        
        vm.prank(owner);
        vm.expectRevert("Funding goal not met yet");
        fundMeV1.withdraw();
    }
    
    function testWithdrawSucceedsAfterGoal() public {
        // Fund with 5 different users
        vm.prank(user1);
        fundMeV1.fund{value: SEND_VALUE}();
        
        vm.prank(user2);
        fundMeV1.fund{value: SEND_VALUE}();
        
        vm.prank(user3);
        fundMeV1.fund{value: SEND_VALUE}();
        
        vm.prank(user4);
        fundMeV1.fund{value: SEND_VALUE}();
        
        vm.prank(user5);
        fundMeV1.fund{value: SEND_VALUE}();
        
        assertTrue(fundMeV1.isGoalMet());
        
        uint256 ownerBalanceBefore = owner.balance;
        uint256 contractBalance = address(fundMeV1).balance;
        
        vm.prank(owner);
        fundMeV1.withdraw();
        
        assertEq(owner.balance, ownerBalanceBefore + contractBalance);
        assertEq(address(fundMeV1).balance, 0);
    }
    
    function testWithdrawOnlyOwner() public {
        // Reach goal
        vm.prank(user1);
        fundMeV1.fund{value: SEND_VALUE}();
        vm.prank(user2);
        fundMeV1.fund{value: SEND_VALUE}();
        vm.prank(user3);
        fundMeV1.fund{value: SEND_VALUE}();
        vm.prank(user4);
        fundMeV1.fund{value: SEND_VALUE}();
        vm.prank(user5);
        fundMeV1.fund{value: SEND_VALUE}();
        
        vm.prank(user1);
        vm.expectRevert();
        fundMeV1.withdraw();
    }
    
    // ======== Upgrade Tests ========
    
    function testUpgradeToV2() public {
        vm.startPrank(owner);
        
        FundMeV2 newImplementation = new FundMeV2();
        fundMeV1.upgradeToAndCall(
            address(newImplementation),
            abi.encodeWithSelector(FundMeV2.initializeV2.selector)
        );
        
        fundMeV2 = FundMeV2(payable(proxy));
        
        assertEq(fundMeV2.version(), 2);
        assertEq(fundMeV2.owner(), owner);
        assertTrue(fundMeV2.refundsEnabled());
        
        vm.stopPrank();
    }
    
    function testUpgradeOnlyOwner() public {
        FundMeV2 newImplementation = new FundMeV2();
        
        vm.prank(user1);
        vm.expectRevert();
        fundMeV1.upgradeToAndCall(
            address(newImplementation),
            abi.encodeWithSelector(FundMeV2.initializeV2.selector)
        );
    }
    
    // ======== V2 Tests ========
    
    function setupV2() internal {
        vm.startPrank(owner);
        FundMeV2 newImplementation = new FundMeV2();
        fundMeV1.upgradeToAndCall(
            address(newImplementation),
            abi.encodeWithSelector(FundMeV2.initializeV2.selector)
        );
        fundMeV2 = FundMeV2(payable(proxy));
        vm.stopPrank();
    }
    
    function testV2LowerMinimum() public {
        setupV2();
        
        vm.prank(user1);
        fundMeV2.fund{value: 0.0009 ether}();
        
        assertEq(fundMeV2.getFundersCount(), 1);
        assertEq(fundMeV2.getAmountFunded(user1), 0.0009 ether);
    }
    
    function testV2TracksFundingAmount() public {
        setupV2();
        
        vm.startPrank(user1);
        fundMeV2.fund{value: 0.001 ether}();
        fundMeV2.fund{value: 0.002 ether}();
        vm.stopPrank();
        
        assertEq(fundMeV2.getAmountFunded(user1), 0.003 ether);
        assertEq(fundMeV2.getFundersCount(), 1);
    }
    
    function testV2Refund() public {
        setupV2();
        
        vm.prank(user1);
        fundMeV2.fund{value: 0.001 ether}();
        
        uint256 balanceBefore = user1.balance;
        
        vm.prank(user1);
        fundMeV2.refund();
        
        assertEq(user1.balance, balanceBefore + 0.001 ether);
        assertEq(fundMeV2.getAmountFunded(user1), 0);
        assertEq(address(fundMeV2).balance, 0);
    }
    
    function testV2RefundFailsAfterGoal() public {
        setupV2();
        
        // Reach goal
        vm.prank(user1);
        fundMeV2.fund{value: 0.001 ether}();
        vm.prank(user2);
        fundMeV2.fund{value: 0.001 ether}();
        vm.prank(user3);
        fundMeV2.fund{value: 0.001 ether}();
        vm.prank(user4);
        fundMeV2.fund{value: 0.001 ether}();
        vm.prank(user5);
        fundMeV2.fund{value: 0.001 ether}();
        
        vm.prank(user1);
        vm.expectRevert("Goal already met, cannot refund");
        fundMeV2.refund();
    }
    
    function testV2ToggleRefunds() public {
        setupV2();
        
        assertTrue(fundMeV2.refundsEnabled());
        
        vm.prank(owner);
        fundMeV2.toggleRefunds();
        
        assertFalse(fundMeV2.refundsEnabled());
        
        vm.prank(user1);
        fundMeV2.fund{value: 0.001 ether}();
        
        vm.prank(user1);
        vm.expectRevert("Refunds are not enabled");
        fundMeV2.refund();
    }
    
    function testV2StatePreservedAfterUpgrade() public {
        // Fund in V1
        vm.prank(user1);
        fundMeV1.fund{value: 0.001 ether}();
        
        vm.prank(user2);
        fundMeV1.fund{value: 0.002 ether}();
        
        assertEq(fundMeV1.getFundersCount(), 2);
        
        // Upgrade
        setupV2();
        
        // Check state preserved
        assertEq(fundMeV2.getFundersCount(), 2);
        assertTrue(fundMeV2.hasFunded(user1));
        assertTrue(fundMeV2.hasFunded(user2));
        assertEq(address(fundMeV2).balance, 0.003 ether);
    }
}