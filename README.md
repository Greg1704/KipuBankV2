# KipuBankV2

An advanced multi-token personal vault banking system built on Ethereum with USD-based accounting and Chainlink price feed integration.

## What's New in V2

KipuBankV2 is a complete evolution of the original KipuBank contract, transforming it from a simple ETH-only vault into a production-ready, multi-asset banking system with real-time USD valuations.

### Major Improvements

#### 1. Multi-Token Support
- **Before (V1):** Only ETH deposits and withdrawals
- **After (V2):** Support for ETH + multiple ERC-20 tokens (USDC, DAI, USDT, etc.)
- **Why:** Users can now diversify their holdings within a single vault, making the bank more versatile and useful for real-world scenarios.

#### 2. USD-Based Accounting with Chainlink Oracles
- **Implementation:** Integration of Chainlink Data Feeds for real-time ETH/USD and token/USD price conversion
- **Why:** All limits (withdrawal limit and bank cap) are now denominated in USD, providing consistent and predictable behavior regardless of crypto market volatility.
- **Key Decision:** We chose to maintain a **unified USD-based withdrawal limit** across all tokens for consistency and user experience simplicity. This means whether you withdraw ETH or USDC, the same $5,000 limit applies.

#### 3. Advanced Access Control
- **Implementation:** OpenZeppelin's `Ownable` contract for role-based permissions
- **Functionality:** 
  - Owner can add new supported tokens with their price feeds
  - Owner can remove token support
  - Critical functions are protected with `onlyOwner` modifier
- **Why:** Allows the bank to evolve over time by supporting new tokens without redeploying the entire contract.

#### 4. Nested Mapping Architecture
- **Structure:** `mapping(address user => mapping(address token => uint256 balance))`
- **Special Convention:** `address(0)` represents native ETH
- **Why:** This provides a clean, gas-efficient way to track multiple tokens per user. Using `address(0)` for ETH creates a consistent interface where ETH is treated like any other asset in the system.

#### 5. Decimal Normalization
- **Implementation:** All USD values are normalized to 6 decimals (USDC standard)
- **Function:** `_convertToUsd()` handles conversion from any token decimals (ETH: 18, USDC: 6, etc.) to the standard 6-decimal USD representation
- **Why:** Different tokens use different decimal places. Normalizing to a common standard ensures accurate accounting and prevents calculation errors.

#### 6. Enhanced Security & Best Practices
- **Custom Errors:** Gas-efficient error handling with descriptive custom errors
- **CEI Pattern:** Strict Checks-Effects-Interactions pattern in all state-changing functions
- **Immutable Variables:** `WITHDRAWAL_LIMIT` and `BANK_CAP` are immutable for security
- **Constants:** `USDC_DECIMALS` and `ETH_ADDRESS` are constants for gas optimization
- **Price Staleness Check:** Rejects oracle prices older than 1 hour
  - **Why this matters:** Cryptocurrency prices can change drastically in an hour. Using stale prices could allow users to deposit/withdraw at incorrect valuations, potentially exploiting the system or losing value.

#### 7. Comprehensive Events
- Detailed event logging for all deposits, withdrawals, and admin actions
- Events include both token amounts and USD values for transparency
- **Why:** Essential for off-chain tracking, analytics, and building user interfaces

## Contract Architecture

### Core Components
```solidity
// Type Declaration
struct TokenInfo {
    bool isSupported;
    AggregatorV3Interface priceFeed;
    uint8 decimals;
}

// Constants
uint8 public constant USDC_DECIMALS = 6;
address public constant ETH_ADDRESS = address(0);

// Immutables
uint256 public immutable WITHDRAWAL_LIMIT;  // USD with 6 decimals
uint256 public immutable BANK_CAP;          // USD with 6 decimals

// State Variables
mapping(address => mapping(address => uint256)) public balances;
mapping(address => TokenInfo) public supportedTokens;
```

### Key Functions

| Function | Access | Description |
|----------|--------|-------------|
| `depositEth()` | Public | Deposit ETH into your vault |
| `depositToken(address, uint256)` | Public | Deposit ERC-20 tokens |
| `withdrawEth(uint256)` | Public | Withdraw ETH from your vault |
| `withdrawToken(address, uint256)` | Public | Withdraw ERC-20 tokens |
| `addSupportedToken(address, address)` | Owner | Add a new supported token with its price feed |
| `removeSupportedToken(address)` | Owner | Remove support for a token |
| `getBankStats()` | View | Get comprehensive bank statistics |
| `getUserBalance(address, address)` | View | Check user balance for a specific token |
| `getUsdValue(address, uint256)` | View | Convert any token amount to USD |

## Deployment Instructions

### Prerequisites
- Foundry installed
- Sepolia testnet ETH
- Alchemy/Infura RPC URL
- Etherscan API key

### Environment Setup

Create a `.env` file:
```env
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY
PRIVATE_KEY=your_private_key_without_0x
ETHERSCAN_API_KEY=your_etherscan_api_key
```

### Deploy to Sepolia
```bash
# Load environment variables
source .env

# Create encrypted keystore (recommended)
cast wallet import deployer --interactive

# Deploy and verify
forge script script/DeployKipuBankV2.s.sol:DeployKipuBankV2 \
    --rpc-url $SEPOLIA_RPC_URL \
    --account deployer \
    --sender YOUR_ADDRESS \
    --broadcast \
    --verify \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    -vvvv
```

### Current Deployment

**Network:** Sepolia Testnet  
**Contract Address:** `0x137E195901Ce69af199F3Fd69674e2F2ab24b78E`  
**Explorer:** [View on Etherscan](https://sepolia.etherscan.io/address/0x137e195901ce69af199f3fd69674e2f2ab24b78e)

**Deployed Parameters:**
- Withdrawal Limit: $5,000 USD
- Bank Cap: $50,000 USD
- ETH/USD Price Feed: `0x694AA1769357215DE4FAC081bf1f309aDC325306` (Chainlink Sepolia)

## How to Interact

### Depositing ETH
```solidity
// Using Remix or Etherscan
// 1. Navigate to the "Write Contract" tab
// 2. Connect your wallet
// 3. Call depositEth() with ETH value (e.g., 0.1 ETH)
```

### Depositing ERC-20 Tokens
```solidity
// First, approve the bank to spend your tokens
// On the token contract:
approve(BANK_ADDRESS, AMOUNT)

// Then deposit:
depositToken(TOKEN_ADDRESS, AMOUNT)
```

### Withdrawing
```solidity
// Withdraw ETH
withdrawEth(AMOUNT_IN_WEI)

// Withdraw tokens
withdrawToken(TOKEN_ADDRESS, AMOUNT)
```

### Adding New Tokens (Owner Only)
```solidity
// Example: Adding USDC support
addSupportedToken(
    USDC_ADDRESS,
    USDC_USD_PRICE_FEED_ADDRESS
)
```

### Checking Balances
```solidity
// Check your ETH balance
getUserBalance(YOUR_ADDRESS, address(0))

// Check your token balance
getUserBalance(YOUR_ADDRESS, TOKEN_ADDRESS)

// Get USD value of an amount
getUsdValue(TOKEN_ADDRESS, AMOUNT)
```

## Design Decisions & Trade-offs

### 1. Unified USD Withdrawal Limit

**Decision:** Single withdrawal limit in USD that applies to all tokens  
**Alternative Considered:** Per-token withdrawal limits  

**Rationale:** 
- Simpler user experience (one limit to remember)
- Fair treatment of all assets
- Demonstrates effective use of Chainlink oracles
- Less complexity in contract logic
- Trade-off: Less flexibility for treating different tokens differently

**Conclusion:** For an educational project demonstrating oracle integration, the unified approach is superior. In production, per-token limits might be preferred for risk management.

### 2. Price Staleness Check (1 hour)

**Decision:** Reject oracle prices older than 1 hour  

**Rationale:**
- Cryptocurrency markets are highly volatile
- Stale prices could lead to incorrect valuations
- 1 hour provides a balance between freshness and avoiding false rejections during low-activity periods
- Protects users from depositing/withdrawing at unfair prices

### 3. Using address(0) for ETH

**Decision:** Represent native ETH as `address(0)` in the balance mappings  

**Rationale:**
- Provides a consistent interface (ETH is treated like any other token)
- Simplifies logic in functions that need to handle both ETH and ERC-20s
- Common pattern in DeFi protocols
- Makes the code more maintainable

### 4. Immutable Limits

**Decision:** `WITHDRAWAL_LIMIT` and `BANK_CAP` are set once at deployment  
**Alternative Considered:** Admin functions to update limits  

**Rationale:**
- Immutability provides user trust (rules won't change)
- Gas savings (immutable variables are cheaper to read)
- Simpler security model (fewer admin functions = smaller attack surface)
- If limits need changing, can deploy a new version

**Trade-off:** Less flexibility, but more security and trust.

### 5. 6-Decimal Normalization

**Decision:** Normalize all USD values to 6 decimals (USDC standard)  

**Rationale:**
- USDC is the most widely used stablecoin standard
- Provides sufficient precision for realistic banking amounts
- Avoids overflow issues with 18 decimals
- Makes USD values more readable ($1,000.00 = 1000000000 in 6 decimals vs 1000000000000000000000 in 18)

## Security Considerations

1. **Reentrancy Protection:** CEI pattern prevents reentrancy attacks
2. **Oracle Manipulation:** Price staleness check mitigates oracle manipulation
3. **Access Control:** Critical functions properly restricted to owner
4. **Integer Overflow:** Solidity 0.8.x has built-in overflow protection
5. **Safe Transfers:** Uses low-level `call()` for ETH and proper ERC-20 interface for tokens

## Testing

The project includes comprehensive tests covering all core functionality:
```bash
# Run all tests
forge test

# Run with detailed output
forge test -vvv

# Run with gas reporting
forge test --gas-report
```

**Test Coverage (15 tests):**

### ETH Operations
- Deposit ETH successfully
- Withdraw ETH successfully  
- Reject zero ETH deposits
- Reject over-withdrawals

### ERC-20 Token Operations
- Deposit tokens successfully
- Withdraw tokens successfully
- Reject deposits without token approval
- Reject unsupported token deposits
- Reject zero token deposits

### Access Control
- Owner can add new tokens
- Non-owner blocked from adding tokens
- Owner can remove tokens
- ETH removal correctly blocked

### View Functions
- Bank statistics retrieval
- USD value conversion with Chainlink

**Testing Strategy:** 
- Uses Foundry's fork testing to interact with real Chainlink price feeds on Sepolia
- Includes mock ERC-20 token for comprehensive token testing
- Validates all security checks and edge cases
- All 15 tests passing

## Project Structure
```
KipuBankV2/
├── src/
│   └── KipuBankV2.sol          # Main contract
├── script/
│   └── DeployKipuBankV2.s.sol  # Deployment script
├── test/
│   └── KipuBankV2.t.sol        # Test suite
├── lib/                        # Dependencies
│   ├── openzeppelin-contracts/
│   ├── chainlink-brownie-contracts/
│   └── forge-std/
├── foundry.toml                # Foundry configuration
└── README.md                   # This file
```

## Useful Links

- [Chainlink Price Feeds](https://docs.chain.link/data-feeds/price-feeds/addresses)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)
- [Foundry Book](https://book.getfoundry.sh/)

## License

MIT License - See LICENSE file for details

## Acknowledgments

Built as part of the Ethereum Development Course at Kipu. This project demonstrates advanced Solidity concepts including:
- Multi-token vault architecture
- Chainlink oracle integration
- OpenZeppelin access control
- Decimal normalization strategies
- Production-ready smart contract patterns

---

**Author:** Gregorio Firmani  
**Course:** Ethereum Development - Kipu  
**Version:** 2.0  
**Date:** October 2025