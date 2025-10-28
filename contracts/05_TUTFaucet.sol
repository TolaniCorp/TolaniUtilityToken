// SPDX-License-Identifier: MIT
// Use a fixed Solidity version to ensure deterministic compilation.
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/// @title TUTFaucet
/// @notice Simple faucet contract for distributing small amounts of TUT tokens for
/// testing and onboarding. Users can claim a fixed amount after a cooldown
/// period. The owner can adjust parameters or refill the faucet balance.
contract TUTFaucet is Initializable, OwnableUpgradeable {
    IERC20Upgradeable public token;
    uint256 public dripAmount;
    uint256 public waitTime;
    mapping(address => uint256) public lastClaim;

    event Dripped(address indexed to, uint256 amount);
    event DripAmountUpdated(uint256 newAmount);
    event WaitTimeUpdated(uint256 newTime);

    /// @dev Initializes the faucet with token address, drip amount and wait time.
    function initialize(address tokenAddress, uint256 amount, uint256 timeSeconds) external initializer {
        require(tokenAddress != address(0), "Invalid token");
        require(amount > 0, "Amount must be > 0");
        __Ownable_init();
        token = IERC20Upgradeable(tokenAddress);
        dripAmount = amount;
        waitTime = timeSeconds;
    }

    /// @notice Claim tokens from the faucet. Can only be called once per wait time.
    function claim() external {
        require(block.timestamp - lastClaim[msg.sender] >= waitTime, "Wait time not passed");
        lastClaim[msg.sender] = block.timestamp;
        require(token.transfer(msg.sender, dripAmount), "Drip failed");
        emit Dripped(msg.sender, dripAmount);
    }

    /// @notice Owner can update the drip amount.
    function setDripAmount(uint256 newAmount) external onlyOwner {
        require(newAmount > 0, "Invalid amount");
        dripAmount = newAmount;
        emit DripAmountUpdated(newAmount);
    }

    /// @notice Owner can update the wait time between claims.
    function setWaitTime(uint256 newWait) external onlyOwner {
        waitTime = newWait;
        emit WaitTimeUpdated(newWait);
    }

    /// @notice Owner can withdraw excess tokens from the faucet.
    function withdraw(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "Invalid recipient");
        require(token.transfer(to, amount), "Withdraw failed");
    }
}