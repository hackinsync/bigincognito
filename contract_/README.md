# BigInc Genesis Contract

## Overview

The BigInc Genesis contract is a comprehensive share management system built on Starknet that allows users to purchase shares using USDT or USDC tokens. The contract includes features for presale management, partner share caps, shareholder tracking, and administrative controls.

## 🚀 Recent Changes & Revamp

### Major Contract Refactoring

The contract has been completely revamped with the following improvements:

#### 1. **Simplified Architecture**
- **Removed OpenZeppelin Components**: Eliminated dependency on `OwnableComponent`, `PausableComponent`, and `ReentrancyGuardComponent`
- **Custom Implementation**: Implemented ownership and pausing functionality directly in the contract
- **Cleaner Storage**: Streamlined storage structure with better organization

#### 2. **Enhanced Partner Share Cap System**
- **Dynamic Cap Management**: Added ability to set and remove partner share caps per token
- **Cap Enforcement**: Prevents minting shares beyond the set cap for specific tokens
- **Tracking**: Maintains separate tracking of shares minted by each partner token

#### 3. **Improved Shareholder Management**
- **Efficient Indexing**: Added `shareholder_index` mapping for O(1) shareholder removal
- **Better List Management**: Optimized shareholder list operations
- **New View Functions**: Added `get_shareholder_count()` and `get_shareholder_at_index()`

#### 4. **Code Organization**
- **Modular Functions**: Split large functions into smaller, focused internal functions
- **Better Validation**: Comprehensive parameter validation with clear error messages
- **Event System**: Enhanced event structure with proper categorization

## 🔧 New Features

### Partner Share Cap System

The contract now supports setting share caps for specific partner tokens:

```cairo
// Set a cap for USDT partner
set_partner_share_cap(usdt_address, 5000000_u256); // 5M shares cap

// Remove the cap
remove_partner_share_cap(usdt_address);

// Check current cap
let cap = get_partner_share_cap(usdt_address);

// Check shares minted by partner
let shares_minted = get_shares_minted_by_partner(usdt_address);
```

### Enhanced Shareholder Management

```cairo
// Get total number of shareholders
let count = get_shareholder_count();

// Get shareholder at specific index
let shareholder = get_shareholder_at_index(0);
```

## 🧪 Testing

### ⚠️ Important Note About Integration Tests

The file `tests/test_partner_share_cap.cairo` contains **integration tests** that demonstrate the partner share cap functionality. However, this is **NOT the recommended approach** for writing integration tests in Cairo/Starknet for the following reasons:

#### Issues with Current Test Approach:

1. **Mixed Test Types**: The file combines unit tests with integration test patterns
2. **Complex Setup**: Uses `snforge_std` cheat codes which are more suitable for unit testing
3. **Hardcoded Values**: Contains magic numbers and hardcoded addresses
4. **Limited Scope**: Tests only specific scenarios rather than comprehensive integration flows

#### Recommended Testing Strategy:

1. **Unit Tests**: Use `snforge_std` for testing individual functions in isolation
2. **Integration Tests**: Use `starknet::testing` for testing contract interactions
3. **Separate Concerns**: Keep unit tests and integration tests in separate files
4. **Mock Contracts**: Use proper mock contracts for external dependencies

### Version Compatibility

**⚠️ Important**: These tests will run successfully on **Cairo version 2.9.4** and compatible Starknet versions. The contract uses Cairo 2.x syntax and features that may not be compatible with older versions.

## 📁 Contract Structure

```
src/
├── lib.cairo                 # Main library file
├── BigIncGenesis.cairo       # Main contract implementation
├── ierc20.cairo             # ERC20 interface
└── mockerc20.cairo          # Mock ERC20 for testing

tests/
├── test_contract.cairo       # Basic contract tests
└── test_partner_share_cap.cairo  # Partner cap tests (see note above)
```

## 🚀 Key Functions

### Core Functions
- `mint_share(token_address)` - Purchase shares with USDT/USDC
- `transfer_share(to, amount)` - Transfer shares to another address
- `donate(token_address, amount)` - Donate tokens to the contract

### Owner Functions
- `withdraw(token_address, amount)` - Withdraw tokens from contract
- `seize_shares(shareholder)` - Seize shares from a shareholder
- `set_partner_share_cap(token_address, cap)` - Set partner share cap
- `remove_partner_share_cap(token_address)` - Remove partner share cap
- `pause()` / `unpause()` - Pause/unpause contract operations

### View Functions
- `get_available_shares()` - Get remaining shares for sale
- `get_shares(address)` - Get shares owned by address
- `get_partner_share_cap(token_address)` - Get partner share cap
- `get_shares_minted_by_partner(token_address)` - Get shares minted by partner

## 🔒 Security Features

1. **Access Control**: Owner-only functions for administrative operations
2. **Pausable**: Contract can be paused in emergency situations
3. **Input Validation**: Comprehensive parameter validation
4. **Partner Caps**: Prevents excessive share minting by partners
5. **Zero Address Checks**: Prevents transfers to zero addresses

## 📊 Share Economics

- **Total Valuation**: $680,000 (680,000,000 with 6 decimals)
- **Presale Valuation**: $457,143 (457,143,000 with 6 decimals)
- **Total Shares**: 100,000,000
- **Presale Shares**: 21,000,000 (21%)
- **Owner Shares**: 18,000,000 (18%)
- **Available Shares**: 82,000,000 (82%)

## 🛠️ Development

### Prerequisites
- Cairo 2.9.4+
- Scarb
- Starknet Foundry (for testing)

### Build
```bash
scarb build
```

### Test
```bash
scarb test
```

### Deploy
```bash
# Deploy with USDT and USDC addresses
scarb deploy
```

## 📝 License

This project is licensed under the MIT License.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## 📞 Support

For questions or support, please open an issue in the repository. 