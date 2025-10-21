// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {KipuBankV2} from "../src/KipuBankV2.sol";
import {console} from "forge-std/console.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Mock ERC20 token for testing
contract MockERC20 {
    string public name = "Mock Token";
    string public symbol = "MOCK";
    uint8 public decimals = 18;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(allowance[from][msg.sender] >= amount, "Insufficient allowance");

        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        allowance[from][msg.sender] -= amount;

        return true;
    }
}

contract KipuBankV2Test is Test {
    KipuBankV2 public bank;
    MockERC20 public mockToken;

    address public owner = address(this);
    address public user = address(0x1);

    // Sepolia Price Feeds
    address constant ETH_USD_FEED = 0x694AA1769357215DE4FAC081bf1f309aDC325306;

    uint256 constant WITHDRAWAL_LIMIT = 5_000 * 10 ** 6; // $5,000
    uint256 constant BANK_CAP = 50_000 * 10 ** 6; // $50,000

    function setUp() public {
        // Fork Sepolia to use real price feeds
        vm.createSelectFork(vm.envString("SEPOLIA_RPC_URL"));

        // Deploy bank
        bank = new KipuBankV2(WITHDRAWAL_LIMIT, BANK_CAP, ETH_USD_FEED);

        // Deploy mock token
        mockToken = new MockERC20();

        // Add mock token as supported (using ETH price feed for simplicity)
        bank.addSupportedToken(address(mockToken), ETH_USD_FEED);

        // Mint tokens to user
        mockToken.mint(user, 100 ether);
    }

    // ============================================
    // ETH Tests
    // ============================================

    function testDepositEth() public {
        vm.deal(user, 1 ether);
        vm.prank(user);

        bank.depositEth{value: 0.1 ether}();

        uint256 balance = bank.getUserBalance(user, address(0));
        assertEq(balance, 0.1 ether);

        console.log("User deposited 0.1 ETH successfully");
    }

    function testWithdrawEth() public {
        // Setup: deposit first
        vm.deal(user, 1 ether);
        vm.prank(user);
        bank.depositEth{value: 0.1 ether}();

        // Test: withdraw
        vm.prank(user);
        bank.withdrawEth(0.05 ether);

        uint256 balance = bank.getUserBalance(user, address(0));
        assertEq(balance, 0.05 ether);

        console.log("User withdrew 0.05 ETH successfully");
    }

    function testCannotDepositZeroEth() public {
        vm.expectRevert(KipuBankV2.InvalidAmount.selector);
        bank.depositEth{value: 0}();

        console.log("Zero ETH deposit correctly rejected");
    }

    function testCannotWithdrawMoreThanBalance() public {
        vm.deal(user, 1 ether);
        vm.prank(user);
        bank.depositEth{value: 0.1 ether}();

        vm.prank(user);
        vm.expectRevert();
        bank.withdrawEth(0.5 ether); // Trying to withdraw more than deposited

        console.log("Over-withdrawal correctly rejected");
    }

    // ============================================
    // ERC-20 Token Tests
    // ============================================

    function testDepositToken() public {
        uint256 depositAmount = 10 ether;

        // User approves bank to spend tokens
        vm.prank(user);
        mockToken.approve(address(bank), depositAmount);

        // User deposits tokens
        vm.prank(user);
        bank.depositToken(address(mockToken), depositAmount);

        // Verify balance
        uint256 balance = bank.getUserBalance(user, address(mockToken));
        assertEq(balance, depositAmount);

        console.log("User deposited 10 tokens successfully");
    }

    function testWithdrawToken() public {
        uint256 depositAmount = 10 ether;
        uint256 withdrawAmount = 1 ether;

        // Setup: deposit first
        vm.startPrank(user);
        mockToken.approve(address(bank), depositAmount);
        bank.depositToken(address(mockToken), depositAmount);

        // Test: withdraw
        bank.withdrawToken(address(mockToken), withdrawAmount);
        vm.stopPrank();

        // Verify balance in bank
        uint256 bankBalance = bank.getUserBalance(user, address(mockToken));
        assertEq(bankBalance, depositAmount - withdrawAmount);

        // Verify user received tokens back
        uint256 userTokenBalance = mockToken.balanceOf(user);
        assertEq(userTokenBalance, 90 ether + withdrawAmount); // 100 - 10 + 5

        console.log("User withdrew 5 tokens successfully");
    }

    function testCannotDepositTokenWithoutApproval() public {
        vm.prank(user);
        vm.expectRevert();
        bank.depositToken(address(mockToken), 10 ether);

        console.log("Token deposit without approval correctly rejected");
    }

    function testCannotDepositUnsupportedToken() public {
        MockERC20 unsupportedToken = new MockERC20();
        unsupportedToken.mint(user, 100 ether);

        vm.startPrank(user);
        unsupportedToken.approve(address(bank), 10 ether);

        vm.expectRevert(abi.encodeWithSelector(KipuBankV2.TokenNotSupported.selector, address(unsupportedToken)));
        bank.depositToken(address(unsupportedToken), 10 ether);
        vm.stopPrank();

        console.log("Unsupported token deposit correctly rejected");
    }

    function testCannotDepositZeroTokens() public {
        vm.prank(user);
        vm.expectRevert(KipuBankV2.InvalidAmount.selector);
        bank.depositToken(address(mockToken), 0);

        console.log("Zero token deposit correctly rejected");
    }

    // ============================================
    // Owner Functions Tests
    // ============================================

    function testOwnerCanAddToken() public {
        MockERC20 newToken = new MockERC20();

        // Owner adds token
        bank.addSupportedToken(address(newToken), ETH_USD_FEED);

        // Verify token is supported
        (bool isSupported,,) = bank.supportedTokens(address(newToken));
        assertTrue(isSupported);

        console.log("Owner added new token successfully");
    }

    function testNonOwnerCannotAddToken() public {
        MockERC20 newToken = new MockERC20();

        vm.prank(user);
        vm.expectRevert();
        bank.addSupportedToken(address(newToken), ETH_USD_FEED);

        console.log("Non-owner correctly blocked from adding tokens");
    }

    function testOwnerCanRemoveToken() public {
        // Owner removes the mock token
        bank.removeSupportedToken(address(mockToken));

        // Verify token is no longer supported
        (bool isSupported,,) = bank.supportedTokens(address(mockToken));
        assertFalse(isSupported);

        console.log("Owner removed token successfully");
    }

    function testCannotRemoveEth() public {
        vm.expectRevert();
        bank.removeSupportedToken(address(0));

        console.log("ETH removal correctly blocked");
    }

    // ============================================
    // View Functions Tests
    // ============================================

    function testGetBankStats() public {
        // Make some deposits
        vm.deal(user, 1 ether);
        vm.prank(user);
        bank.depositEth{value: 0.5 ether}();

        (
            uint256 totalDeposits,
            uint256 totalWithdrawals,
            uint256 totalDepositedUsdValue,
            uint256 availableCapacityUsd
        ) = bank.getBankStats();

        assertEq(totalDeposits, 1);
        assertEq(totalWithdrawals, 0);
        assertTrue(totalDepositedUsdValue > 0); // Should have USD value
        assertTrue(availableCapacityUsd < BANK_CAP); // Should have used some capacity

        console.log("Bank stats retrieved successfully");
        console.log("   Total USD deposited:", totalDepositedUsdValue);
        console.log("   Available capacity:", availableCapacityUsd);
    }

    function testGetUsdValue() public view {
        uint256 ethAmount = 1 ether;
        uint256 usdValue = bank.getUsdValue(address(0), ethAmount);

        assertTrue(usdValue > 0);
        console.log("USD conversion working");
        console.log("   1 ETH =", usdValue / 10 ** 6, "USD");
    }
}
