# Upgradeable FundMe Smart Contract

A production-ready upgradeable crowdfunding smart contract built with Foundry, demonstrating the UUPS (Universal Upgradeable Proxy Standard) proxy pattern.

## Overview

This project implements a crowdfunding contract with two versions:
- **V1**: Basic crowdfunding with goal-based withdrawals
- **V2**: Enhanced version with refund functionality and lower minimum contribution

## Features

### FundMe V1
- Users can fund with a minimum of 0.001 ETH
- Goal-based system: Owner can withdraw when 5 funders are reached
- Owner-only withdrawal function
- Track total funders and contract balance

### FundMe V2 (Upgraded)
- Lower minimum: Users can fund with 0.0009 ETH
- Refund mechanism: Users can request refunds before goal is met
- Toggle refunds: Owner can enable/disable refund functionality
- Enhanced tracking: Map funders to their contribution amounts
- Backward compatible: All V1 state preserved after upgrade

## Architecture

This project uses the UUPS (Universal Upgradeable Proxy Standard) pattern. Users interact with the proxy contract, which delegates calls to the implementation contract using delegatecall. The proxy address remains constant while the implementation can be upgraded from V1 to V2.

### Deployed Addresses (Sepolia Testnet)
- **Proxy**: `0x55C1De9BB4BD9aa0B2C7b5C2836666384dB47bB9`
- **FundMeV1 Implementation**: `0xF9Bdb5b23c9D83d0A2592688bfDd13CFCC3aA03B`
- **FundMeV2 Implementation**: `0xd2Be2B68436576175918DA0b59EB7FDd27621Cf4`

Note: Always interact with the proxy address, not the implementation contracts directly.

## Prerequisites

- Foundry (forge, cast, anvil)
- An Ethereum wallet with Sepolia ETH
- Alchemy or Infura RPC URL
- Etherscan API key for contract verification

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd foundry-upgradeable
```

2. Install dependencies:
```bash
forge install
```

3. Create a `.env` file:
```bash
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/your-api-key
PRIVATE_KEY=your-private-key
ETHERSCAN_API_KEY=your-etherscan-api-key
PROXY_ADDRESS=0x55C1De9BB4BD9aa0B2C7b5C2836666384dB47bB9
```

4. Load environment variables:
```bash
source .env
```

## Deployment Guide

### Step 1: Deploy FundMe V1

Deploy the initial version with proxy:

```bash
forge script script/DeployFundMe.s.sol:DeployFundMe \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  -vvvv
```

This deploys:
- FundMeV1 implementation contract
- ERC1967 proxy contract
- Initializes the proxy with V1 logic

### Step 2: Interact with V1

Test funding with V1's minimum (0.001 ETH):

```bash
cast send $PROXY_ADDRESS "fund()" \
  --value 0.001ether \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

Test with below minimum (should fail):

```bash
cast send $PROXY_ADDRESS "fund()" \
  --value 0.0009ether \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

### Step 3: Upgrade to V2

Upgrade the proxy to point to V2 implementation:

```bash
forge script script/UpgradeToV2.s.sol:UpgradeToV2 \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  -vvvv
```

### Step 4: Interact with V2

Test funding with V2's lower minimum (0.0009 ETH):

```bash
cast send $PROXY_ADDRESS "fund()" \
  --value 0.0009ether \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

This should now succeed, demonstrating the upgrade.

## Using Interaction Scripts

The Interact.s.sol script provides multiple functions for interacting with the deployed contract.

### Fund the Contract

```bash
forge script script/Interact.s.sol:Interact \
  --sig "fund()" \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  -vvvv
```

### Check Contract Status

```bash
forge script script/Interact.s.sol:Interact \
  --sig "status()" \
  --rpc-url $SEPOLIA_RPC_URL
```

### Withdraw Funds (Owner Only)

```bash
forge script script/Interact.s.sol:Interact \
  --sig "withdraw()" \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  -vvvv
```

Note: Withdrawal only works when the goal is met (5 funders).

### Request Refund (V2 Only)

```bash
forge script script/Interact.s.sol:Interact \
  --sig "refund()" \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  -vvvv
```

### Toggle Refunds (V2 Only, Owner)

```bash
forge script script/Interact.s.sol:Interact \
  --sig "toggleRefunds()" \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  -vvvv
```

## Reading Contract Data with Cast

### Check Amount Funded by Address

```bash
cast call $PROXY_ADDRESS \
  "getAmountFunded(address)(uint256)" \
  <FUNDER_ADDRESS> \
  --rpc-url $SEPOLIA_RPC_URL
```

Convert result to ETH:

```bash
cast call $PROXY_ADDRESS \
  "getAmountFunded(address)(uint256)" \
  <FUNDER_ADDRESS> \
  --rpc-url $SEPOLIA_RPC_URL | cast to-unit ether
```

### Check Contract Version

```bash
cast call $PROXY_ADDRESS "version()(uint256)" --rpc-url $SEPOLIA_RPC_URL
```

Returns: 1 for V1, 2 for V2

### Check Number of Funders

```bash
cast call $PROXY_ADDRESS "getFundersCount()(uint256)" --rpc-url $SEPOLIA_RPC_URL
```

### Check Contract Balance

```bash
cast call $PROXY_ADDRESS "getBalance()(uint256)" --rpc-url $SEPOLIA_RPC_URL | cast to-unit ether
```

### Check if Goal is Met

```bash
cast call $PROXY_ADDRESS "isGoalMet()(bool)" --rpc-url $SEPOLIA_RPC_URL
```

### Check Refunds Status (V2 Only)

```bash
cast call $PROXY_ADDRESS "refundsEnabled()(bool)" --rpc-url $SEPOLIA_RPC_URL
```

## Testing

Run the test suite:

```bash
forge test
```

Run with verbose output:

```bash
forge test -vvv
```

Run specific test:

```bash
forge test --match-test testUpgrade -vvv
```

## Key Concepts Demonstrated

### UUPS Proxy Pattern
- Proxy contract holds state and delegates calls to implementation
- Implementation logic can be upgraded without changing proxy address
- All state is preserved during upgrades

### Upgradeability
- Implementation contracts are deployed separately
- Proxy is upgraded to point to new implementation
- State variables must be compatible between versions
- New state variables can be added in upgrades

### Initialization
- Upgradeable contracts use `initialize()` instead of constructors
- Each version has its own initializer (V1: `initialize()`, V2: `initializeV2()`)
- Initializers are protected to prevent re-initialization

### Access Control
- Owner-only functions protected with `onlyOwner` modifier
- Owner set during initialization and transferred via OpenZeppelin's Ownable

## Security Considerations

1. **Storage Layout**: Maintained compatibility between V1 and V2
2. **Initialization**: Protected against re-initialization attacks
3. **Access Control**: Owner-only functions for critical operations
4. **Upgradeability**: Only owner can upgrade the contract
5. **Minimum Funding**: Enforced to prevent spam transactions

## Gas Optimization

- V2 funding uses less gas than V1 due to optimized logic
- Efficient mapping for funder tracking
- Minimal storage updates during operations

## Troubleshooting

### "Could not find target contract"
Make sure you're using the correct contract name and function signature with the `--sig` flag.

### "Goal not met yet"
The withdrawal function requires 5 funders before allowing withdrawal. Fund the contract more times or from different addresses.

### "Minimum funding is X ETH"
Make sure you're sending at least the minimum amount (0.001 ETH for V1, 0.0009 ETH for V2).

### Verification Issues
If contract verification fails, try running the verification command separately:

```bash
forge verify-contract <CONTRACT_ADDRESS> \
  src/FundMeV2.sol:FundMeV2 \
  --chain sepolia \
  --etherscan-api-key $ETHERSCAN_API_KEY
```

## License

MIT

## Resources

- [Foundry Documentation](https://book.getfoundry.sh/)
- [OpenZeppelin Upgradeable Contracts](https://docs.openzeppelin.com/contracts/4.x/upgradeable)
- [UUPS Proxy Pattern](https://eips.ethereum.org/EIPS/eip-1822)
- [EIP-1967: Proxy Storage Slots](https://eips.ethereum.org/EIPS/eip-1967)