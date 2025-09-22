// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title KipuBank - Personal Vault Banking System
/// @notice A decentralized banking contract that allows users to deposit and withdraw ETH
/// @dev Implements secure patterns including checks-effects-interactions and custom errors
contract KipuBank {

    /// @notice Maximum amount that can be withdrawn per transaction
    /// @dev Set once during deployment and cannot be changed
    uint256 public immutable withdrawalLimit;
    
    /// @notice Maximum total ETH capacity of the bank
    /// @dev Set once during deployment and cannot be changed
    uint256 public immutable bankCap;
    
    /// @notice Initializes the bank with withdrawal and capacity limits
    /// @param _withdrawalLimit Maximum ETH per withdrawal transaction
    /// @param _bankCap Maximum total ETH the bank can hold
    constructor(uint256 _withdrawalLimit, uint256 _bankCap) {
        withdrawalLimit = _withdrawalLimit;
        bankCap = _bankCap;
    }

    /// @notice Total number of deposit operations performed
    /// @dev Incremented on each successful deposit
    uint256 public deposits_count;
    
    /// @notice Total number of withdrawal operations performed
    /// @dev Incremented on each successful withdrawal
    uint256 public withdrawals_count;
    
    /// @notice Total ETH currently deposited in the bank
    /// @dev Updated on deposits (+) and withdrawals (-)
    uint256 public total_deposited;
    
    /// @notice Maps user addresses to their individual vault balances
    /// @dev Updated on deposits and withdrawals for each user
    mapping(address => uint256) public balances;

    /// @notice Emitted when a user successfully deposits ETH
    /// @param user Address of the depositor
    /// @param amount Amount of ETH deposited
    /// @param newBalance User's new total balance after deposit
    event Deposit(address indexed user, uint256 amount, uint256 newBalance);
    
    /// @notice Emitted when a user successfully withdraws ETH
    /// @param user Address of the withdrawer
    /// @param amount Amount of ETH withdrawn
    /// @param newBalance User's new total balance after withdrawal
    event Withdrawal(address indexed user, uint256 amount, uint256 newBalance);

    /// @notice Thrown when user attempts to withdraw more than their balance
    /// @param requested Amount user tried to withdraw
    /// @param available User's actual available balance
    error UnsufficientBalance(uint256 requested, uint256 available);
    
    /// @notice Thrown when deposit would exceed bank's total capacity
    /// @param requested Amount user tried to deposit
    /// @param availableSpace Remaining capacity in the bank
    error ExceedBankCap(uint256 requested, uint256 availableSpace);
    
    /// @notice Thrown when withdrawal amount exceeds per-transaction limit
    /// @param requested Amount user tried to withdraw
    /// @param limit Maximum allowed per transaction
    error ExceededWithdrawalLimit(uint256 requested, uint256 limit);
    
    /// @notice Thrown when user attempts to deposit or withdraw 0 ETH
    error InvalidTransaction();

    /// @notice Validates user has sufficient balance for withdrawal
    /// @param amount Amount to be withdrawn
    modifier enoughBalance(uint256 amount) {
        if (balances[msg.sender] < amount) {
            revert UnsufficientBalance(amount, balances[msg.sender]);
        }
        _;
    }

    /// @notice Validates deposit won't exceed bank capacity
    /// @param amount Amount to be deposited
    modifier withinBankCap(uint256 amount) {
        if (total_deposited + amount > bankCap) {
            revert ExceedBankCap(amount, _calculateAvailableSpace());
        }
        _;
    }

    /// @notice Validates withdrawal amount doesn't exceed per-transaction limit
    /// @param amount Amount to be withdrawn
    modifier withinWithdrawalLimit(uint256 amount) {
        if (amount > withdrawalLimit) {
            revert ExceededWithdrawalLimit(amount, withdrawalLimit);
        }
        _;
    }

    /// @notice Validates transaction amount is greater than zero
    /// @param amount Amount to validate
    modifier validTransaction(uint256 amount) {
        if (amount == 0) {
            revert InvalidTransaction();
        }
        _;
    }

    /// @notice Deposit ETH into your personal vault
    /// @dev Validates amount and bank capacity, updates balances and counters
    function deposit() external payable validTransaction(msg.value) withinBankCap(msg.value) {
        balances[msg.sender] += msg.value;
        total_deposited += msg.value;
        deposits_count += 1;
        emit Deposit(msg.sender, msg.value, balances[msg.sender]);
    }

    /// @notice Withdraw ETH from your personal vault
    /// @dev Validates amount, balance and limits, then transfers ETH to user
    /// @param amount Amount of ETH to withdraw (in wei)
    function withdrawal(uint256 amount) external validTransaction(amount) enoughBalance(amount) withinWithdrawalLimit(amount) {
        balances[msg.sender] -= amount;
        total_deposited -= amount;
        withdrawals_count += 1;
        payable(msg.sender).transfer(amount);
        emit Withdrawal(msg.sender, amount, balances[msg.sender]);
    }

    /// @notice Get comprehensive bank statistics with named returns
    /// @dev Returns key metrics in a single call for efficiency
    /// @return totalDeposits Total number of deposits made
    /// @return totalWithdrawals Total number of withdrawals made
    /// @return currentDeposited Total ETH currently in the bank
    /// @return availableSpace Remaining capacity for new deposits
    function getBankStats() external view returns (
        uint256 totalDeposits,
        uint256 totalWithdrawals,
        uint256 currentDeposited,
        uint256 availableSpace
    ) {
        return (deposits_count, withdrawals_count, total_deposited, _calculateAvailableSpace());
    }

    /// @notice Calculate remaining deposit capacity
    /// @dev Internal function to compute available space in the bank
    /// @return Available space for deposits in wei
    function _calculateAvailableSpace() private view returns (uint256) {
        return bankCap - total_deposited;
    }
}