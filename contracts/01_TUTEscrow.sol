// SPDX-License-Identifier: MIT
// Specify an exact Solidity version instead of a floating one to avoid
// accidental changes in compiler behaviour. Using a fixed pragma ensures
// that the contract is always compiled with the intended compiler version.
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
// Import the draft permit interface to allow single-transaction deposits using EIP-2612 permits.
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/// @title TUTEscrow
/// @notice A reusable escrow contract for the Tolani ecosystem. Payers deposit TUT
/// tokens into escrow for specific payees. Funds can be released by the payer
/// or payee (after expiration) or refunded if the deadline lapses without
/// release. Designed for upgradeability and optimal gas usage.
/// @dev All amounts are denominated in the same ERC20 token (e.g. TUT). The
/// contract uses a simple hash to index escrow agreements. See README for
/// integration details.
contract TUTEscrow is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    struct Escrow {
        address payer;
        address payee;
        uint256 amount;
        uint256 expireAt;
        bool released;
    }

    /// @notice Mapping of escrow id to escrow details
    mapping(bytes32 => Escrow) public escrows;
    /// @notice ERC20 token used for payments
    IERC20Upgradeable public token;

    /// @dev Cached permit interface for tokens that support EIP-2612. May be zero if token doesn't implement permit.
    IERC20PermitUpgradeable private _permitToken;

    event Deposited(bytes32 indexed id, address indexed payer, address indexed payee, uint256 amount, uint256 expireAt);
    event Released(bytes32 indexed id, address indexed payer, address indexed payee, uint256 amount);
    event Refunded(bytes32 indexed id, address indexed payer, uint256 amount);

    /// @dev Initializes the escrow with a given ERC20 token address. Can only be called once.
    function initialize(address tokenAddress) external initializer {
        require(tokenAddress != address(0), "Invalid token");
        __Ownable_init();
        __ReentrancyGuard_init();
        token = IERC20Upgradeable(tokenAddress);
        // Attempt to cast token address to IERC20PermitUpgradeable. If the token
        // does not implement permit, calls to permit will revert. This allows
        // depositWithPermit() to work with tokens that support EIP-2612 while
        // still compiling when they do not.
        _permitToken = IERC20PermitUpgradeable(tokenAddress);
    }

    /// @notice Generates a unique escrow identifier. Payer should call this off-chain or on-chain.
    /// @param payer Address of the person depositing funds
    /// @param payee Address of the intended recipient
    /// @param amount Amount of tokens to be held in escrow
    /// @param expireAt Unix timestamp when the payee can independently claim funds
    function computeId(
        address payer,
        address payee,
        uint256 amount,
        uint256 expireAt
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(payer, payee, amount, expireAt));
    }

    /// @notice Deposit tokens into escrow. Requires prior approval for token transfer.
    /// @param payee Address of the payee
    /// @param amount Amount of tokens to deposit
    /// @param expireAt Timestamp after which the payee can claim funds if not released
    function deposit(address payee, uint256 amount, uint256 expireAt) external nonReentrant returns (bytes32 id) {
        require(payee != address(0), "Invalid payee");
        require(amount > 0, "Amount must be > 0");
        require(expireAt > block.timestamp, "Expiry must be in the future");
        id = computeId(msg.sender, payee, amount, expireAt);
        Escrow storage e = escrows[id];
        require(e.amount == 0, "Escrow already exists");
        e.payer = msg.sender;
        e.payee = payee;
        e.amount = amount;
        e.expireAt = expireAt;
        e.released = false;
        // Transfer tokens from payer
        require(token.transferFrom(msg.sender, address(this), amount), "Token transfer failed");
        emit Deposited(id, msg.sender, payee, amount, expireAt);
    }

    /// @notice Deposit tokens into escrow using an ERC20 permit. This enables
    /// a single-transaction deposit without requiring a prior approve() call.
    /// The payer signs a permit off-chain allowing this contract to spend the
    /// specified `amount` of tokens. A third party or the payer can then
    /// submit the signed permit along with the escrow parameters to create
    /// the escrow in one transaction.
    /// @param payer Address providing the funds and signature
    /// @param payee Address of the payee
    /// @param amount Amount of tokens to deposit
    /// @param expireAt Timestamp when the payee can claim funds if not released
    /// @param deadline EIP-2612 permit deadline
    /// @param v Permit signature parameter
    /// @param r Permit signature parameter
    /// @param s Permit signature parameter
    function depositWithPermit(
        address payer,
        address payee,
        uint256 amount,
        uint256 expireAt,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external nonReentrant returns (bytes32 id) {
        require(payer != address(0), "Invalid payer");
        require(payee != address(0), "Invalid payee");
        require(amount > 0, "Amount must be > 0");
        require(expireAt > block.timestamp, "Expiry must be in the future");
        // Compute escrow id deterministically using payer, payee, amount and expiry
        id = computeId(payer, payee, amount, expireAt);
        Escrow storage e = escrows[id];
        require(e.amount == 0, "Escrow already exists");
        // Execute permit on the token to approve this contract. This will revert
        // if the token does not implement the permit function.
        _permitToken.permit(payer, address(this), amount, deadline, v, r, s);
        // Populate escrow struct
        e.payer = payer;
        e.payee = payee;
        e.amount = amount;
        e.expireAt = expireAt;
        e.released = false;
        // Transfer tokens from payer after successful permit
        require(token.transferFrom(payer, address(this), amount), "Token transfer failed");
        emit Deposited(id, payer, payee, amount, expireAt);
    }

    /// @notice Release funds from escrow to the payee. Can be called by the payer at any time or
    /// by the payee after expiration. Once released, the escrow is marked as finished.
    /// @param id The escrow id returned by deposit()
    function release(bytes32 id) external nonReentrant {
        Escrow storage e = escrows[id];
        require(e.amount > 0, "Escrow does not exist");
        require(!e.released, "Already released");
        require(msg.sender == e.payer || (msg.sender == e.payee && block.timestamp >= e.expireAt), "Not authorized");
        e.released = true;
        require(token.transfer(e.payee, e.amount), "Token transfer failed");
        emit Released(id, e.payer, e.payee, e.amount);
        // Clean up storage to refund gas on next write
        delete escrows[id];
    }

    /// @notice Refund payer if escrow expired and payee did not claim. Can only be called by the payer.
    /// @param id The escrow id
    function refund(bytes32 id) external nonReentrant {
        Escrow storage e = escrows[id];
        require(e.amount > 0, "Escrow does not exist");
        require(!e.released, "Already released");
        require(block.timestamp >= e.expireAt, "Not expired yet");
        require(msg.sender == e.payer, "Only payer can refund");
        e.released = true;
        require(token.transfer(e.payer, e.amount), "Token transfer failed");
        emit Refunded(id, e.payer, e.amount);
        delete escrows[id];
    }

    /// @notice Owner can rescue tokens accidentally sent to this contract (other than the configured token).
    /// @param otherToken Address of the token to rescue
    /// @param to Recipient of the rescued tokens
    /// @param amount Amount to rescue
    function rescueTokens(IERC20Upgradeable otherToken, address to, uint256 amount) external onlyOwner {
        require(address(otherToken) != address(token), "Cannot rescue escrow token");
        require(otherToken.transfer(to, amount), "Rescue failed");
    }
}