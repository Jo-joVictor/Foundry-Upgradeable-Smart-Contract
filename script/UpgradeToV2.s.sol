// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {FundMeV2} from "../src/FundMeV2.sol";
import {FundMeV1} from "../src/FundMeV1.sol";

/**
 * @title UpgradeToV2
 * @notice Script to upgrade FundMeV1 to FundMeV2
 */
contract UpgradeToV2 is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address proxyAddress = vm.envAddress("PROXY_ADDRESS");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy new implementation
        FundMeV2 newImplementation = new FundMeV2();
        console.log("FundMeV2 Implementation deployed at:", address(newImplementation));
        
        // Get proxy instance
        FundMeV1 proxy = FundMeV1(payable(proxyAddress));
        
        // Upgrade to V2
        proxy.upgradeToAndCall(
            address(newImplementation),
            abi.encodeWithSelector(FundMeV2.initializeV2.selector)
        );
        
        console.log("Upgraded proxy at:", proxyAddress);
        console.log("New version:", FundMeV2(payable(proxyAddress)).version());
        
        vm.stopBroadcast();
    }
}