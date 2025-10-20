// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {KipuBankV2} from "../src/KipuBankV2.sol";
import {console} from "forge-std/console.sol";

contract DeployKipuBankV2 is Script {
    // Sepolia Chainlink ETH/USD Price Feed
    address constant SEPOLIA_ETH_USD_FEED = 0x694AA1769357215DE4FAC081bf1f309aDC325306;

    // Constructor parameters (in USD with 6 decimals)
    uint256 constant WITHDRAWAL_LIMIT = 5_000 * 10 ** 6; // $5,000 USD
    uint256 constant BANK_CAP = 50_000 * 10 ** 6; // $50,000 USD

    function run() external returns (KipuBankV2) {
        vm.startBroadcast();

        KipuBankV2 bank = new KipuBankV2(WITHDRAWAL_LIMIT, BANK_CAP, SEPOLIA_ETH_USD_FEED);

        console.log("KipuBankV2 deployed to:", address(bank));
        console.log("Owner:", bank.owner());
        console.log("Withdrawal Limit (USD):", bank.WITHDRAWAL_LIMIT());
        console.log("Bank Cap (USD):", bank.BANK_CAP());

        vm.stopBroadcast();

        return bank;
    }
}
