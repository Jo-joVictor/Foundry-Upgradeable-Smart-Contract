// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {FundMeV1} from "../src/FundMeV1.sol";
import {FundMeV2} from "../src/FundMeV2.sol";

/**
 * @title Interact
 * @notice Script for interacting with deployed FundMe contracts
 */
contract Interact is Script {
    
    /**
     * @notice Fund the contract
     */
    function fund() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address proxyAddress = vm.envAddress("PROXY_ADDRESS");
        
        vm.startBroadcast(privateKey);
        
        FundMeV1 fundMe = FundMeV1(payable(proxyAddress));
        fundMe.fund{value: 0.001 ether}();
        
        console.log("Successfully funded with 0.001 ETH");
        console.log("Current funders count:", fundMe.getFundersCount());
        console.log("Contract balance:", fundMe.getBalance());
        
        vm.stopBroadcast();
    }
    
    /**
     * @notice Withdraw funds (owner only)
     */
    function withdraw() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address proxyAddress = vm.envAddress("PROXY_ADDRESS");
        
        vm.startBroadcast(privateKey);
        
        FundMeV1 fundMe = FundMeV1(payable(proxyAddress));
        
        require(fundMe.isGoalMet(), "Goal not met yet");
        
        uint256 balanceBefore = address(fundMe.owner()).balance;
        fundMe.withdraw();
        uint256 balanceAfter = address(fundMe.owner()).balance;
        
        console.log("Withdrawal successful!");
        console.log("Amount withdrawn:", balanceAfter - balanceBefore);
        
        vm.stopBroadcast();
    }
    
    /**
     * @notice Refund (V2 only)
     */
    function refund() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address proxyAddress = vm.envAddress("PROXY_ADDRESS");
        
        vm.startBroadcast(privateKey);
        
        FundMeV2 fundMe = FundMeV2(payable(proxyAddress));
        
        uint256 amountFunded = fundMe.getAmountFunded(vm.addr(privateKey));
        console.log("Amount funded:", amountFunded);
        
        fundMe.refund();
        
        console.log("Refund successful!");
        
        vm.stopBroadcast();
    }
    
    /**
     * @notice Check contract status
     */
    function status() external view {
        address proxyAddress = vm.envAddress("PROXY_ADDRESS");
        
        FundMeV1 fundMe = FundMeV1(payable(proxyAddress));
        
        console.log("=== FundMe Status ===");
        console.log("Proxy Address:", proxyAddress);
        console.log("Owner:", fundMe.owner());
        console.log("Version:", fundMe.version());
        console.log("Funders Count:", fundMe.getFundersCount());
        console.log("Contract Balance:", fundMe.getBalance());
        console.log("Goal Met:", fundMe.isGoalMet());
        
        // If V2, show additional info
        try FundMeV2(payable(proxyAddress)).refundsEnabled() returns (bool enabled) {
            console.log("Refunds Enabled:", enabled);
            console.log("Minimum Funding:", FundMeV2(payable(proxyAddress)).getMinimumFunding());
        } catch {
            console.log("This is Version 1");
        }
    }
    
    /**
     * @notice Toggle refunds (V2 only, owner only)
     */
    function toggleRefunds() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address proxyAddress = vm.envAddress("PROXY_ADDRESS");
        
        vm.startBroadcast(privateKey);
        
        FundMeV2 fundMe = FundMeV2(payable(proxyAddress));
        fundMe.toggleRefunds();
        
        console.log("Refunds toggled!");
        console.log("Refunds enabled:", fundMe.refundsEnabled());
        
        vm.stopBroadcast();
    }
}