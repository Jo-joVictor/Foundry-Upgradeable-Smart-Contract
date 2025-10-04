# FundMe Upgradeable Smart Contract

A crowdfunding smart contract built with Solidity and Foundry that implements the UUPS proxy pattern for upgradeability, featuring goal-based withdrawals and optional refund functionality.

## Features

- **UUPS Proxy Pattern**: Upgradeable contract design using OpenZeppelin's UUPS implementation
- **Goal-based Funding**: Requires 5 funders before owner can withdraw
- **Minimum Funding**: V1 requires 0.001 ETH, V2 reduces to 0.0009 ETH
- **Refund Capability**: V2 adds refund functionality for funders before goal is met
- **Amount Tracking**: V2 tracks individual funding amounts per address
- **Owner Controls**: Only owner can withdraw funds and toggle features
- **State Preservation**: All state data preserved across upgrades
- **Event-driven**: Comprehensive event logging for transparency

## Quick Start

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)

### Installation

```bash
git clone <your-repo-url>
cd fundme-upgradeable
forge install
```

### Environment Setup

Create a `.env` file:
```bash
PRIVATE_KEY=your_private_key
SEPOLIA_RPC_URL=your_sepolia_rpc_url
ETHERSCAN_API_KEY=your_etherscan_api_key
PROXY_ADDRESS=deployed_proxy_address
```

## Usage

### Deploy V1

```bash
# Deploy to local anvil
forge script script/DeployFundMe.s.sol --rpc-url http://localhost:8545 --broadcast

# Deploy to Sepolia testnet
forge script script/DeployFundMe.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify
```

### Fund the Contract

```bash
# Using interaction script
forge script script/Interact.s.sol:Interact --sig "fund()" --rpc-url $SEPOLIA_RPC_URL --broadcast

# Using cast directly
cast send $PROXY_ADDRESS "fund()" --value 0.001ether --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY
```

### Withdraw Funds (Owner Only)

```bash
# Using interaction script
forge script script/Interact.s.sol:Interact --sig "withdraw()" --rpc-url $SEPOLIA_RPC_URL --broadcast

# Using cast directly
cast send $PROXY_ADDRESS "withdraw()" --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY
```

### Check Status

```bash
forge script script/Interact.s.sol:Interact --sig "status()" --rpc-url $SEPOLIA_RPC_URL
```

### Upgrade to V2

```bash
forge script script/UpgradeToV2.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify
```

### V2 Specific Functions

```bash
# Request refund
forge script script/Interact.s.sol:Interact --sig "refund()" --rpc-url $SEPOLIA_RPC_URL --broadcast

# Toggle refunds (owner only)
forge script script/Interact.s.sol:Interact --sig "toggleRefunds()" --rpc-url $SEPOLIA_RPC_URL --broadcast

# Check amount funded by address
cast call $PROXY_ADDRESS "getAmountFunded(address)(uint256)" <ADDRESS> --rpc-url $SEPOLIA_RPC_URL
```

## Contract Architecture

### Core Contracts

- **FundMeV1.sol**: Initial implementation with basic crowdfunding functionality
- **FundMeV2.sol**: Upgraded implementation with refund capability and lower minimum

### Inheritance Structure

```
FundMeV1
├── Initializable (OpenZeppelin)
├── UUPSUpgradeable (OpenZeppelin)
└── OwnableUpgradeable (OpenZeppelin)

FundMeV2
└── FundMeV1
```

### Proxy Pattern

The contract uses the UUPS (Universal Upgradeable Proxy Standard) pattern:
- **Proxy Contract**: Holds state and delegates calls to implementation
- **Implementation Contract**: Contains the logic
- **Upgrades**: Owner can upgrade implementation while preserving state

### FundMeV1 Functions

- `initialize()`: Initializes the contract (replaces constructor)
- `fund()`: Accept ETH donations with 0.001 ETH minimum
- `withdraw()`: Owner withdraws all funds after goal is met
- `getFundersCount()`: Returns number of unique funders
- `getBalance()`: Returns contract balance
- `getFunders()`: Returns array of all funder addresses
- `isGoalMet()`: Checks if 5 or more funders exist
- `hasFunded(address)`: Checks if address has funded
- `version()`: Returns contract version (1)

### FundMeV2 Functions

All V1 functions plus:

- `initializeV2()`: Reinitializer for V2 upgrade
- `fund()`: Overridden with 0.0009 ETH minimum and amount tracking
- `refund()`: Allows funders to get refund before goal is met
- `toggleRefunds()`: Owner can enable/disable refunds
- `getAmountFunded(address)`: Returns total amount funded by address
- `getMinimumFunding()`: Returns current minimum funding amount
- `refundsEnabled()`: Returns whether refunds are currently enabled
- `version()`: Returns contract version (2)

### Deployment Scripts

- **DeployFundMe.s.sol**: Deploys implementation and proxy for V1
- **UpgradeToV2.s.sol**: Upgrades existing proxy to V2 implementation
- **Interact.s.sol**: Interaction scripts for funding, withdrawing, and checking status

## Testing

Run the complete test suite:

```bash
# Run all tests
forge test

# Run with verbose output
forge test -vvv

# Run specific test
forge test --match-test testUpgradeToV2

# Generate coverage report
forge coverage
```

### Test Coverage

#### V1 Tests

- **Initialization**: Verifies owner, version, and initial state
- **Funding**: Tests basic funding with minimum requirements
- **Multiple Funders**: Validates tracking of multiple unique funders
- **Duplicate Funding**: Same funder counted only once
- **Withdrawal Restrictions**: Cannot withdraw before goal is met
- **Withdrawal Success**: Owner withdraws after 5 funders
- **Access Control**: Only owner can withdraw

#### Upgrade Tests

- **Upgrade Process**: Successfully upgrades V1 to V2
- **State Preservation**: Funders and balances preserved after upgrade
- **Access Control**: Only owner can perform upgrade
- **Version Update**: Version number correctly incremented

#### V2 Tests

- **Lower Minimum**: Accepts 0.0009 ETH funding
- **Amount Tracking**: Tracks total funded per address
- **Refund Functionality**: Users can refund before goal
- **Refund Restrictions**: Cannot refund after goal is met
- **Toggle Refunds**: Owner can enable/disable refunds
- **State Migration**: V1 state accessible in V2

## Security Features

- **UUPS Proxy Pattern**: Secure upgradeability with owner authorization
- **Access Control**: Ownable pattern restricts privileged functions
- **Initialize Protection**: Prevents re-initialization attacks
- **Storage Collision Prevention**: V2 appends new variables to avoid conflicts
- **Reentrancy Protection**: Safe call patterns for ETH transfers
- **Goal-based Withdrawals**: Prevents premature fund withdrawal
- **Refund Guards**: Multiple checks prevent unauthorized refunds

## Gas Optimization

- Efficient storage with mappings for tracking funders
- Events for off-chain data tracking
- Minimal state changes during upgrades
- Optimized loops avoided where possible

## Upgrade Process

### How Upgrades Work

1. Deploy new implementation contract (V2)
2. Call `upgradeToAndCall()` on proxy with V2 address
3. New implementation's `initializeV2()` runs once
4. All future calls routed to V2 logic
5. Original state data preserved in proxy

### Storage Layout

**V1 Storage:**
```solidity
uint256 MINIMUM_FUNDING (constant)
uint256 FUNDING_GOAL (constant)
address[] funders
mapping(address => bool) hasFunded
```

**V2 Added Storage:**
```solidity
uint256 MINIMUM_FUNDING_V2 (constant)
mapping(address => uint256) funderToAmount
bool refundsEnabled
```

Storage slots are preserved to prevent collision during upgrades.

## Funding Goal Mechanics

### Entry Requirements

- Minimum funding: 0.001 ETH (V1) or 0.0009 ETH (V2)
- Contract must be in OPEN state
- No maximum funding limit

### Withdrawal Requirements

- Must have 5 or more unique funders
- Only contract owner can withdraw
- Transfers entire contract balance to owner

### Refund Mechanics (V2)

- Only available before goal is met
- Can be toggled on/off by owner
- Returns full amount funded by caller
- Prevents refund after goal reached

## Events

### V1 Events

- `Funded(address indexed funder, uint256 amount)`: Emitted when user funds
- `Withdrawn(address indexed owner, uint256 amount)`: Emitted when owner withdraws

### V2 Events

All V1 events plus:

- `Refunded(address indexed funder, uint256 amount)`: Emitted on successful refund
- `RefundsToggled(bool enabled)`: Emitted when refunds are toggled

## Error Messages

### V1 Errors

- "Minimum funding is 0.001 ETH": Sent value below minimum
- "Funding goal not met yet": Withdrawal attempted before 5 funders
- "No funds to withdraw": Contract balance is zero
- "Withdrawal failed": ETH transfer failed

### V2 Errors

- "Minimum funding is 0.0009 ETH": Sent value below V2 minimum
- "Refunds are not enabled": Refund attempted when disabled
- "Goal already met, cannot refund": Refund attempted after goal reached
- "No funds to refund": Caller has no funded amount
- "Refund failed": ETH transfer failed

## Use Cases

- **Crowdfunding Campaigns**: Collect funds for projects with goal thresholds
- **Community Fundraisers**: Group funding with refund options
- **Product Pre-sales**: Collect payments with refund capability
- **Milestone-based Funding**: Release funds only after participation goals met
- **Upgradeable Treasuries**: Flexible contract logic while preserving funds

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add comprehensive tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Resources

- [Foundry Documentation](https://book.getfoundry.sh/)
- [OpenZeppelin Upgradeable Contracts](https://docs.openzeppelin.com/contracts/4.x/upgradeable)
- [UUPS Proxy Pattern](https://docs.openzeppelin.com/contracts/4.x/api/proxy#UUPSUpgradeable)
- [Proxy Upgrade Pattern](https://docs.openzeppelin.com/upgrades-plugins/1.x/proxies)
- [Solidity Documentation](https://docs.soliditylang.org/)
