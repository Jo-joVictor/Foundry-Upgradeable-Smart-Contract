// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title FundMeV1
 * @notice A crowdfunding contract where users can fund with minimum 0.001 ETH
 * @dev Uses UUPS proxy pattern for upgradeability
 */
contract FundMeV1 is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    // State variables
    uint256 public constant MINIMUM_FUNDING = 0.001 ether;
    uint256 public constant FUNDING_GOAL = 5; // Number of funders needed
    
    address[] public funders;
    mapping(address => bool) public hasFunded;
    
    // Events
    event Funded(address indexed funder, uint256 amount);
    event Withdrawn(address indexed owner, uint256 amount);
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    
    /**
     * @notice Initializes the contract
     * @dev Replaces constructor for upgradeable contracts
     */
    function initialize() public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
    }
    
    /**
     * @notice Allows users to fund the contract
     * @dev Minimum funding amount is 0.001 ETH
     */
    function fund() public payable virtual{
        require(msg.value >= MINIMUM_FUNDING, "Minimum funding is 0.001 ETH");
        
        // Only add to funders array if first time funding
        if (!hasFunded[msg.sender]) {
            funders.push(msg.sender);
            hasFunded[msg.sender] = true;
        }
        
        emit Funded(msg.sender, msg.value);
    }
    
    /**
     * @notice Allows owner to withdraw funds when goal is met
     * @dev Only callable by owner when 5 or more funders exist
     */
    function withdraw() public onlyOwner {
        require(funders.length >= FUNDING_GOAL, "Funding goal not met yet");
        
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Withdrawal failed");
        
        emit Withdrawn(owner(), balance);
    }
    
    /**
     * @notice Returns the number of funders
     */
    function getFundersCount() public view returns (uint256) {
        return funders.length;
    }
    
    /**
     * @notice Returns the contract balance
     */
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @notice Returns all funders
     */
    function getFunders() public view returns (address[] memory) {
        return funders;
    }
    
    /**
     * @notice Checks if funding goal is met
     */
    function isGoalMet() public view returns (bool) {
        return funders.length >= FUNDING_GOAL;
    }
    
    /**
     * @dev Function that authorizes an upgrade to a new implementation
     * @param newImplementation Address of the new implementation
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
    
    /**
     * @notice Returns the version of the contract
     */
    function version() public pure virtual returns (uint256) {
        return 1;
    }
}