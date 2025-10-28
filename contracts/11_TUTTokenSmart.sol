// SPDX-License-Identifier: MIT
// Pin the compiler version to avoid floating pragmas and unexpected behaviour.
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20CappedUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/// @title TUTTokenSmart
/// @notice ERC20 utility token with 18 decimals, capped supply, burnable,
/// pausable and upgradeable via UUPS. Adds support for EIP-2612 permits and
/// ERC-2771 meta‑transactions via a trusted forwarder. Includes role-based
/// access control for minting, pausing, and upgrading.
contract TUTTokenSmart is Initializable, ERC20Upgradeable, ERC20CappedUpgradeable, ERC20BurnableUpgradeable, ERC20PermitUpgradeable, PausableUpgradeable, ERC2771ContextUpgradeable, AccessControlUpgradeable, UUPSUpgradeable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /// @dev Initializes the token. Can only be called once. Pass owner to grant roles.
    /// @param owner Address to receive admin, pauser, minter, and upgrader roles
    /// @param initialSupply Initial mint amount (in smallest unit)
    /// @param cap Maximum supply cap (in smallest unit)
    /// @param forwarder Address of the trusted forwarder for meta‑transactions
    function initialize(
        address owner,
        uint256 initialSupply,
        uint256 cap,
        address forwarder
    ) external initializer {
        require(owner != address(0), "Invalid owner");
        require(forwarder != address(0), "Invalid forwarder");
        __ERC20_init("Tolani Utility Token", "TUT");
        __ERC20Capped_init(cap);
        __ERC20Burnable_init();
        __ERC20Permit_init("Tolani Utility Token");
        __Pausable_init();
        __ERC2771Context_init(forwarder);
        __AccessControl_init();
        __UUPSUpgradeable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(MINTER_ROLE, owner);
        _grantRole(PAUSER_ROLE, owner);
        _grantRole(UPGRADER_ROLE, owner);
        // Mint initial supply
        if (initialSupply > 0) {
            _mint(owner, initialSupply);
        }
    }

    /// @notice Overrides the maximum supply. Part of ERC20CappedUpgradeable.
    function _maxSupply() internal view override returns (uint256) {
        return super.cap();
    }

    /// @notice Mint new tokens. Only addresses with MINTER_ROLE may call.
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    /// @notice Pause token transfers. Only addresses with PAUSER_ROLE may call.
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /// @notice Unpause token transfers. Only addresses with PAUSER_ROLE may call.
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /// @dev Ensures transfers are blocked when paused and respects cap
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(ERC20Upgradeable, ERC20CappedUpgradeable, PausableUpgradeable) {
        super._beforeTokenTransfer(from, to, amount);
        require(!paused(), "Token is paused");
    }

    /// @dev Authorizes contract upgrade. Restricted to UPGRADER_ROLE.
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    /// @dev Override _msgSender to use ERC2771Context
    function _msgSender() internal view override(ContextUpgradeable, ERC2771ContextUpgradeable) returns (address sender) {
        return ERC2771ContextUpgradeable._msgSender();
    }

    /// @dev Override _msgData to use ERC2771Context
    function _msgData() internal view override(ContextUpgradeable, ERC2771ContextUpgradeable) returns (bytes calldata) {
        return ERC2771ContextUpgradeable._msgData();
    }

    uint256[50] private __gap;
}