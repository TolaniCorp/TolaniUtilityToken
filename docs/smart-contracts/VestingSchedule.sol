// SPDX-License-Identifier: MIT
// Fix compiler version to avoid floating pragma.
pragma solidity 0.8.20;

/**
 * @title VestingSchedule
 * @dev A linear vesting contract that releases tokens over time. The contract
 *      holds a supply of tokens and gradually releases them to a beneficiary.
 */
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VestingSchedule is Ownable {
    /// @notice The ERC20 token being vested and gradually released to the beneficiary.
    IERC20 public immutable token;
    /// @notice The address that will receive vested tokens over time.
    address public beneficiary;
    /// @notice Timestamp (seconds since epoch) when vesting begins.
    uint256 public immutable start;
    /// @notice Timestamp of the cliff: no tokens vest before this time.
    uint256 public immutable cliff;
    /// @notice Total duration of the vesting schedule in seconds. After this period
    /// has elapsed from `start`, all tokens will be vested.
    uint256 public immutable duration;
    /// @notice Amount of tokens that have already been released to the beneficiary.
    uint256 public released;

    /**
     * @param token_ The ERC20 token being vested
     * @param beneficiary_ The address receiving vested tokens
     * @param start_ Timestamp when vesting starts
     * @param cliffDuration Duration of the cliff period in seconds
     * @param duration_ Total duration of the vesting schedule in seconds
     */
    constructor(
        IERC20 token_,
        address beneficiary_,
        uint256 start_,
        uint256 cliffDuration,
        uint256 duration_
    ) {
        require(duration_ > cliffDuration, "Duration must be greater than cliff");
        token = token_;
        beneficiary = beneficiary_;
        start = start_;
        cliff = start_ + cliffDuration;
        duration = duration_;
    }

    /**
     * @dev Compute the amount of tokens that have vested up to now.
     */
    function vestedAmount() public view returns (uint256) {
        uint256 total = token.balanceOf(address(this)) + released;
        if (block.timestamp < cliff) {
            return 0;
        } else if (block.timestamp >= start + duration) {
            return total;
        } else {
            return (total * (block.timestamp - start)) / duration;
        }
    }

    /**
     * @dev Compute the amount of tokens that can be released at the current time.
     */
    function releasable() public view returns (uint256) {
        return vestedAmount() - released;
    }

    /**
     * @dev Release vested tokens to the beneficiary. Anyone can call this
     *      function, but only the beneficiary will receive the tokens.
     */
    function release() external {
        uint256 amount = releasable();
        released += amount;
        token.transfer(beneficiary, amount);
    }

    /**
     * @dev Update the beneficiary. Only the contract owner can call this.
     * @param newBeneficiary The address of the new beneficiary
     */
    function setBeneficiary(address newBeneficiary) external onlyOwner {
        beneficiary = newBeneficiary;
    }
}