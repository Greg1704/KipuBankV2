// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KipuBank {

    uint256 immutable withdrawalLimit;
    uint256 immutable bankCap;
    constructor(uint256 _withdrawalLimit, uint256 _bankCap) {
        withdrawalLimit = _withdrawalLimit;
        bankCap = _bankCap;
    }

    //state variables
    uint256 public deposits_count;
    uint256 public withdrawals_count;
    uint256 public total_deposited;
    mapping(address => uint256) public balances;

    //events
    event Deposit(address indexed user, uint256 amount, uint256 newBalance);
    event Withdrawal(address indexed user, uint256 amount, uint256 newBalance);

    //errors
    error UnsufficientBalance(uint256 requested, uint256 available);
    error ExceedBankCap(uint256 requested, uint256 availableSpace);
    error ExceededWithdrawalLimit(uint256 requested, uint256 limit);
    error InvalidTransaction();

    //modifiers
    modifier enoughBalance(uint256 amount) {
        if (balances[msg.sender] < amount) {
            revert UnsufficientBalance(amount, balances[msg.sender]);
        }
        _;
    }

    modifier withinBankCap(uint256 amount) {
        if (total_deposited + amount > bankCap) {
            revert ExceedBankCap(amount, bankCap - total_deposited);
        }
        _;
    }

    modifier withinWithdrawalLimit(uint256 amount) {
        if (amount > withdrawalLimit) {
            revert ExceededWithdrawalLimit(amount, withdrawalLimit);
        }
        _;
    }

    modifier validTransaction(uint256 amount) {
        if (amount == 0) {
            revert InvalidTransaction();
        }
        _;
    }
}