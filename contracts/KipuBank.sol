// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KipuBank {

    uint256 immutable withdrawalLimit;
    uint256 immutable bankCap;
    constructor(uint256 _withdrawalLimit, uint256 _bankCap) {
        withdrawalLimit = _withdrawalLimit;
        bankCap = _bankCap;
    }

    /* Variables de estado a incluir:
    - deposits_count: Contador de depósitos
    - withdrawals_count: Contador de retiros
    - balances: Mapeo de balances por usuario
    */

    uint256 public deposits_count;
    uint256 public withdrawals_count;
    mapping(address => uint256) public balances;

    event Deposit()
    event Withdrawal()
    event UnsufficientBalance()
    event ExceedBankCap()
    event ExceededWithdrawalLimit()
}