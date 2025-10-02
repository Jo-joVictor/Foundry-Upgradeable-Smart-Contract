// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {FundMeV1} from "./FundMeV1.sol";

/**
 * @title FundMeV2
 * @notice Upgraded version with refund functionality and reduced minimum funding
 * @dev Inherits from FundMeV1 and adds new features
 */
contract FundMeV2 is FundMeV1 {
    // New state variables (appended to avoid storage collision)
    uint256 public constant MINIMUM_FUNDING_V2 = 0.0009 ether;
    mapping(address => uint256) public funderToAmount;
    bool public refundsEnabled;
    
    // New events
    event Refunded(address indexed funder, uint256 amount);
    event RefundsToggled(bool enabled);
    
    /**
     * @notice Reinitializer for V2 upgrade
     * @dev Called once during upgrade to set up new state
     */
    function initializeV2() public reinitializer(2) {
        refundsEnabled = true;
    }
    
    /**
     * @notice Enhanced fund function with amount tracking
     * @dev Overrides V1 fund function with lower minimum
     */
    function fund() public payable override {
        require(msg.value >= MINIMUM_FUNDING_V2, "Minimum funding is 0.0009 ETH");
        
        // Only add to funders array if first time funding
        if (!hasFunded[msg.sender]) {
            funders.push(msg.sender);
            hasFunded[msg.sender] = true;
        }
        
        // Track total amount funded by user
        funderToAmount[msg.sender] += msg.value;
        
        emit Funded(msg.sender, msg.value);
    }
    
    /**
     * @notice Allows funders to request refund before goal is met
     * @dev Only works if refunds are enabled and goal not met
     */
    function refund() public {
        require(refundsEnabled, "Refunds are not enabled");
        require(!isGoalMet(), "Goal already met, cannot refund");
        require(funderToAmount[msg.sender] > 0, "No funds to refund");
        
        uint256 amountToRefund = funderToAmount[msg.sender];
        funderToAmount[msg.sender] = 0;
        
        (bool success, ) = payable(msg.sender).call{value: amountToRefund}("");
        require(success, "Refund failed");
        
        emit Refunded(msg.sender, amountToRefund);
    }
    
    /**
     * @notice Allows owner to toggle refund functionality
     * @dev Can be used to disable refunds once goal is near
     */
    function toggleRefunds() public onlyOwner {
        refundsEnabled = !refundsEnabled;
        emit RefundsToggled(refundsEnabled);
    }
    
    /**
     * @notice Returns the amount funded by a specific address
     */
    function getAmountFunded(address funder) public view returns (uint256) {
        return funderToAmount[funder];
    }
    
    /**
     * @notice Returns the current minimum funding amount
     */
    function getMinimumFunding() public pure returns (uint256) {
        return MINIMUM_FUNDING_V2;
    }
    
    /**
     * @notice Returns the version of the contract
     */
    function version() public pure override returns (uint256) {
        return 2;
    }
}