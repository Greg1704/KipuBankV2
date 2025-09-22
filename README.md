# KipuBank

A personal vault banking smart contract that allows users to securely deposit and withdraw ETH.

## Description

KipuBank is a decentralized banking system built on Ethereum. Each user has their own personal vault where they can deposit ETH and withdraw it when needed.

**Main features:**
- Deposit ETH into personal vault
- Controlled withdrawals with per-transaction limit
- Maximum bank capacity limit
- Tracking of all operations

## Deployment Instructions

### What you need:
- Remix IDE (https://remix.ethereum.org)
- MetaMask with testnet ETH

### Steps:

1. **Prepare the contract**
   - Open Remix IDE
   - Create a file called `KipuBank.sol`
   - Copy and paste the contract code

2. **Compile**
   - Go to "Solidity Compiler" tab
   - Select version 0.8.0 or higher
   - Click "Compile KipuBank.sol"

3. **Deploy**
   - Go to "Deploy & Run Transactions"
   - Connect MetaMask (Injected Web3)
   - Configure the parameters:
     - `_withdrawalLimit`: Maximum ETH per withdrawal (in wei)
     - `_bankCap`: Maximum bank capacity (in wei)

**Example parameters:**
- Withdrawal limit: `1000000000000000000` (1 ETH)
- Bank capacity: `5000000000000000000` (5 ETH)

4. **Verify**
   - Copy the contract address
   - Verify on your testnet's block explorer

## Important: Units and Values

⚠️ **Critical Notice: The contract uses different units for different operations**

**For deposits:**
- Use the "Value" field in **ETH** (example: 1 ETH)
- Remix/Etherscan automatically converts to wei internally

**For withdrawals and all queries:**
- All functions use **wei** as the unit
- 1 ETH = 1,000,000,000,000,000,000 wei
- Use converter: https://eth-converter.com/

**Examples:**
- **Deposit 1 ETH**: "Value" field = `1` ETH
- **Withdraw 1 ETH**: Parameter = `1000000000000000000` wei
- **Check balance**: Returns in wei (e.g., `1000000000000000000` = 1 ETH)

## How to Interact with the Contract

### Make a deposit:
1. In Remix, find the `deposit` function
2. In the "Value" field, enter the amount of ETH (e.g., `1`)
3. Select "Ether" as unit
4. Click "transact"

### Make a withdrawal:
1. Find the `withdrawal` function
2. Enter the amount in **wei** you want to withdraw (e.g., `1000000000000000000` for 1 ETH)
3. Click "transact"

### Query information:
- **Your balance**: Call `balances` with your address (returns wei)
- **Bank statistics**: Call `getBankStats` (all values in wei)
- **Limits**: Check `withdrawalLimit` and `bankCap` (both in wei)

## Main Functions

| Function | Description |
|----------|-------------|
| `deposit()` | Deposit ETH into your vault |
| `withdrawal(amount)` | Withdraw ETH from your vault |
| `getBankStats()` | View bank statistics |
| `balances(address)` | View balance of an address |

## Common Errors

- **InvalidTransaction**: You tried to deposit/withdraw 0 ETH
- **UnsufficientBalance**: You don't have enough balance to withdraw
- **ExceededWithdrawalLimit**: You tried to withdraw more than the allowed limit
- **ExceedBankCap**: The deposit would exceed the bank's maximum capacity

## Project Structure

```
kipu-bank/
├── contracts/
│   └── KipuBank.sol
└── README.md
```

## Contract Information

**Deployed contract:**
- Network: Sepolia Testnet
- Address: `0x8cAA02e3C6d74A70A69B253FdD59b713fE0dea5c`
- Explorer: https://sepolia.etherscan.io/address/0x8caa02e3c6d74a70a69b253fdd59b713fe0dea5c

## Notes

- 1 ETH = 1,000,000,000,000,000,000 wei
- Use an online converter for easier calculations: https://eth-converter.com/
- This contract is designed for educational purposes

---

**License:** MIT