// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/// @title KipuBankV2 - Multi-Token Personal Vault Banking System
/// @notice A decentralized banking contract supporting ETH and ERC-20 tokens with USD-based accounting
/// @dev Implements Chainlink price feeds for USD conversion and OpenZeppelin's Ownable for access control
contract KipuBankV2 is Ownable {
    
    // ============================================
    // Type Declarations
    // ============================================
    
    /// @notice Represents a supported token with its price feed
    struct TokenInfo {
        bool isSupported;
        AggregatorV3Interface priceFeed;
        uint8 decimals;
    }
    
    // ============================================
    // Constants
    // ============================================
    
    /// @notice Standard decimals for internal USD accounting (USDC standard)
    uint8 public constant USDC_DECIMALS = 6;
    
    /// @notice Address representing native ETH in mappings
    address public constant ETH_ADDRESS = address(0);
    
    // ============================================
    // Immutable Variables
    // ============================================
    
    /// @notice Maximum amount that can be withdrawn per transaction (in USD, 6 decimals)
    uint256 public immutable WITHDRAWAL_LIMIT;
    
    /// @notice Maximum total USD value the bank can hold (in USD, 6 decimals)
    uint256 public immutable BANK_CAP;
    
    // ============================================
    // State Variables
    // ============================================
    
    /// @notice Nested mapping: user address => token address => balance (in token's native decimals)
    mapping(address user => mapping(address token => uint256 balance)) public balances;
    
    /// @notice Mapping of token addresses to their configuration
    mapping(address token => TokenInfo info) public supportedTokens;
    
    /// @notice Total number of deposit operations
    uint256 public depositsCount;
    
    /// @notice Total number of withdrawal operations
    uint256 public withdrawalsCount;
    
    /// @notice Total USD value deposited in the bank (in 6 decimals)
    uint256 public totalDepositedUsd;
    
    // ============================================
    // Events
    // ============================================
    
    /// @notice Emitted when a user deposits tokens
    event Deposit(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 usdValue,
        uint256 newBalance
    );
    
    /// @notice Emitted when a user withdraws tokens
    event Withdrawal(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 usdValue,
        uint256 newBalance
    );
    
    /// @notice Emitted when a new token is added by owner
    event TokenAdded(address indexed token, address indexed priceFeed);
    
    /// @notice Emitted when a token is removed by owner
    event TokenRemoved(address indexed token);
    
    // ============================================
    // Custom Errors
    // ============================================
    
    error InsufficientBalance(uint256 requested, uint256 available);
    error ExceedBankCap(uint256 requested, uint256 availableSpace);
    error ExceededWithdrawalLimit(uint256 requested, uint256 limit);
    error InvalidAmount();
    error TransferFailed();
    error TokenNotSupported(address token);
    error TokenAlreadySupported(address token);
    error InvalidPriceFeed();
    error StalePrice();
    
    // ============================================
    // Constructor
    // ============================================
    
    /// @notice Initializes the bank with limits and ETH price feed
    /// @param _withdrawalLimit Maximum USD value per withdrawal (6 decimals)
    /// @param _bankCap Maximum total USD value the bank can hold (6 decimals)
    /// @param _ethUsdPriceFeed Chainlink ETH/USD price feed address
    constructor(
        uint256 _withdrawalLimit,
        uint256 _bankCap,
        address _ethUsdPriceFeed
    ) Ownable(msg.sender) {
        WITHDRAWAL_LIMIT = _withdrawalLimit;
        BANK_CAP = _bankCap;
        
        // Add ETH as supported token
        supportedTokens[ETH_ADDRESS] = TokenInfo({
            isSupported: true,
            priceFeed: AggregatorV3Interface(_ethUsdPriceFeed),
            decimals: 18
        });
        
        emit TokenAdded(ETH_ADDRESS, _ethUsdPriceFeed);
    }
    
    // ============================================
    // External Functions
    // ============================================
    
    /// @notice Deposit ETH into your personal vault
    function depositEth() external payable {
        if (msg.value == 0) revert InvalidAmount();
        
        uint256 usdValue = _convertToUsd(ETH_ADDRESS, msg.value);
        
        if (totalDepositedUsd + usdValue > BANK_CAP) {
            revert ExceedBankCap(usdValue, BANK_CAP - totalDepositedUsd);
        }
        
        // Effects
        balances[msg.sender][ETH_ADDRESS] += msg.value;
        totalDepositedUsd += usdValue;
        depositsCount += 1;
        
        emit Deposit(msg.sender, ETH_ADDRESS, msg.value, usdValue, balances[msg.sender][ETH_ADDRESS]);
    }
    
    /// @notice Deposit ERC-20 tokens into your personal vault
    /// @param token Address of the ERC-20 token
    /// @param amount Amount of tokens to deposit
    function depositToken(address token, uint256 amount) external {
        if (amount == 0) revert InvalidAmount();
        if (!supportedTokens[token].isSupported) revert TokenNotSupported(token);
        if (token == ETH_ADDRESS) revert TokenNotSupported(token); // Use depositEth instead
        
        uint256 usdValue = _convertToUsd(token, amount);
        
        if (totalDepositedUsd + usdValue > BANK_CAP) {
            revert ExceedBankCap(usdValue, BANK_CAP - totalDepositedUsd);
        }
        
        // Effects
        balances[msg.sender][token] += amount;
        totalDepositedUsd += usdValue;
        depositsCount += 1;
        
        // Interactions
        bool success = IERC20(token).transferFrom(msg.sender, address(this), amount);
        if (!success) revert TransferFailed();
        
        emit Deposit(msg.sender, token, amount, usdValue, balances[msg.sender][token]);
    }
    
    /// @notice Withdraw ETH from your personal vault
    /// @param amount Amount of ETH to withdraw (in wei)
    function withdrawEth(uint256 amount) external {
        if (amount == 0) revert InvalidAmount();
        if (balances[msg.sender][ETH_ADDRESS] < amount) {
            revert InsufficientBalance(amount, balances[msg.sender][ETH_ADDRESS]);
        }
        
        uint256 usdValue = _convertToUsd(ETH_ADDRESS, amount);
        
        if (usdValue > WITHDRAWAL_LIMIT) {
            revert ExceededWithdrawalLimit(usdValue, WITHDRAWAL_LIMIT);
        }
        
        // Effects
        balances[msg.sender][ETH_ADDRESS] -= amount;
        totalDepositedUsd -= usdValue;
        withdrawalsCount += 1;
        
        // Interactions
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) revert TransferFailed();
        
        emit Withdrawal(msg.sender, ETH_ADDRESS, amount, usdValue, balances[msg.sender][ETH_ADDRESS]);
    }
    
    /// @notice Withdraw ERC-20 tokens from your personal vault
    /// @param token Address of the ERC-20 token
    /// @param amount Amount of tokens to withdraw
    function withdrawToken(address token, uint256 amount) external {
        if (amount == 0) revert InvalidAmount();
        if (!supportedTokens[token].isSupported) revert TokenNotSupported(token);
        if (token == ETH_ADDRESS) revert TokenNotSupported(token); // Use withdrawEth instead
        if (balances[msg.sender][token] < amount) {
            revert InsufficientBalance(amount, balances[msg.sender][token]);
        }
        
        uint256 usdValue = _convertToUsd(token, amount);
        
        if (usdValue > WITHDRAWAL_LIMIT) {
            revert ExceededWithdrawalLimit(usdValue, WITHDRAWAL_LIMIT);
        }
        
        // Effects
        balances[msg.sender][token] -= amount;
        totalDepositedUsd -= usdValue;
        withdrawalsCount += 1;
        
        // Interactions
        bool success = IERC20(token).transfer(msg.sender, amount);
        if (!success) revert TransferFailed();
        
        emit Withdrawal(msg.sender, token, amount, usdValue, balances[msg.sender][token]);
    }
    
    /// @notice Add support for a new ERC-20 token (only owner)
    /// @param token Address of the ERC-20 token
    /// @param priceFeed Chainlink price feed for token/USD
    function addSupportedToken(address token, address priceFeed) external onlyOwner {
        if (token == ETH_ADDRESS) revert TokenAlreadySupported(token);
        if (supportedTokens[token].isSupported) revert TokenAlreadySupported(token);
        
        // Validate price feed
        AggregatorV3Interface feed = AggregatorV3Interface(priceFeed);
        try feed.latestRoundData() returns (uint80, int256 price, uint256, uint256, uint80) {
            if (price <= 0) revert InvalidPriceFeed();
        } catch {
            revert InvalidPriceFeed();
        }
        
        uint8 decimals = IERC20Metadata(token).decimals();
        
        supportedTokens[token] = TokenInfo({
            isSupported: true,
            priceFeed: feed,
            decimals: decimals
        });
        
        emit TokenAdded(token, priceFeed);
    }
    
    /// @notice Remove support for a token (only owner)
    /// @param token Address of the token to remove
    function removeSupportedToken(address token) external onlyOwner {
        if (token == ETH_ADDRESS) revert TokenNotSupported(token); // Cannot remove ETH
        if (!supportedTokens[token].isSupported) revert TokenNotSupported(token);
        
        delete supportedTokens[token];
        
        emit TokenRemoved(token);
    }
    
    /// @notice Get bank statistics
    function getBankStats() external view returns (
        uint256 totalDeposits,
        uint256 totalWithdrawals,
        uint256 totalDepositedUsdValue,
        uint256 availableCapacityUsd
    ) {
        return (
            depositsCount,
            withdrawalsCount,
            totalDepositedUsd,
            BANK_CAP - totalDepositedUsd
        );
    }
    
    /// @notice Get user's balance for a specific token
    /// @param user Address of the user
    /// @param token Address of the token (use address(0) for ETH)
    function getUserBalance(address user, address token) external view returns (uint256) {
        return balances[user][token];
    }
    
    /// @notice Get USD value of a token amount
    /// @param token Address of the token
    /// @param amount Amount in token's native decimals
    function getUsdValue(address token, uint256 amount) external view returns (uint256) {
        return _convertToUsd(token, amount);
    }
    
    // ============================================
    // Internal Functions
    // ============================================
    
    /// @notice Convert token amount to USD value (6 decimals)
    /// @param token Address of the token
    /// @param amount Amount in token's native decimals
    /// @return USD value with 6 decimals
    function _convertToUsd(address token, uint256 amount) internal view returns (uint256) {
        if (!supportedTokens[token].isSupported) revert TokenNotSupported(token);
        
        TokenInfo memory tokenInfo = supportedTokens[token];
        
        // Get price from Chainlink
        (, int256 price, , uint256 updatedAt, ) = tokenInfo.priceFeed.latestRoundData();
        
        if (price <= 0) revert InvalidPriceFeed();
        if (block.timestamp - updatedAt > 1 hours) revert StalePrice();
        
        uint8 priceDecimals = tokenInfo.priceFeed.decimals();
        
        // Convert: (amount * price) / (10^tokenDecimals) * (10^USDC_DECIMALS) / (10^priceDecimals)
        // Simplified: (amount * price * 10^USDC_DECIMALS) / (10^tokenDecimals * 10^priceDecimals)
        
        // Casting to uint256 is safe because Chainlink price feeds return positive prices
        // and we check price > 0 above
        // forge-lint: disable-next-line(unsafe-typecast)
        uint256 usdValue = (amount * uint256(price) * (10 ** USDC_DECIMALS)) 
                          / (10 ** tokenInfo.decimals * 10 ** priceDecimals);
        
        return usdValue;
    }
    
    // ============================================
    // Fallback Functions
    // ============================================
    
    receive() external payable {
        revert("Use depositEth() function");
    }
    
    fallback() external payable {
        revert("Use depositEth() function");
    }
}