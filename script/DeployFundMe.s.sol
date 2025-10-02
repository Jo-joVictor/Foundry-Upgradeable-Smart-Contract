// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {FundMeV1} from "../src/FundMeV1.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @title DeployFundMe
 * @notice Deployment script for FundMeV1 with UUPS proxy
 */
contract DeployFundMe is Script {
    function run() external returns (address) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy implementation
        FundMeV1 implementation = new FundMeV1();
        console.log("FundMeV1 Implementation deployed at:", address(implementation));
        
        // Encode initializer data
        bytes memory data = abi.encodeWithSelector(FundMeV1.initialize.selector);
        
        // Deploy proxy
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), data);
        console.log("Proxy deployed at:", address(proxy));
        
        vm.stopBroadcast();
        
        return address(proxy);
    }
}