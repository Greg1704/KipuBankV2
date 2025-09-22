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

## How to Interact with the Contract

### Make a deposit:
1. In Remix, find the `deposit` function
2. In the "Value" field, enter the amount of ETH
3. Select "Ether" as unit
4. Click "transact"

### Make a withdrawal:
1. Find the `withdrawal` function
2. Enter the amount in wei you want to withdraw
3. Click "transact"

### Query information:
- **Your balance**: Call `balances` with your address
- **Bank statistics**: Call `getBankStats`
- **Limits**: Check `withdrawalLimit` and `bankCap`

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
- Network: [Complete after deployment]
- Address: [Complete after deployment]
- Explorer: [Complete after deployment]

## Notes

- 1 ETH = 1,000,000,000,000,000,000 wei
- Use an online converter for easier calculations: https://eth-converter.com/
- This contract is designed for educational purposes

---

**License:** MIT
