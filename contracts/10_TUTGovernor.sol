// SPDX-License-Identifier: MIT
// Specify an exact Solidity version instead of a floating one to prevent
// unintended upgrades and maintain reproducibility.
pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/governance/GovernorUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorSettingsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorCountingSimpleUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorVotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorTimelockControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/// @title TUTGovernor
/// @notice A comprehensive on‑chain governance contract for the Tolani Utility Token (TUT).
///         This contract leverages OpenZeppelin’s upgradeable Governor framework to provide
///         proposal creation, voting, quorum management, and timelocked execution. It is
///         designed for integration with the TUT token (via ERC20Votes) and a TimelockController
///         so that passed proposals are executed after a delay, allowing time for community
///         review or cancellation. All parameters—voting delay, voting period, quorum and
///         proposal threshold—can be set during initialization.
///
///         Note: This contract must be deployed behind an upgradeable proxy. It is
///         intentionally separate from the TUTToken contract to enforce modularity and
///         enable independent upgrades. See docs/UPGRADES.md for details on deploying
///         and upgrading governance contracts.
contract TUTGovernor is Initializable, GovernorUpgradeable, GovernorSettingsUpgradeable, GovernorCountingSimpleUpgradeable, GovernorVotesUpgradeable, GovernorTimelockControlUpgradeable {
    /// @notice Initialize the TUTGovernor with required parameters and linked contracts.
    /// @param token The ERC20Votes token used to determine voting power (e.g. TUTToken)
    /// @param timelock The TimelockController that will queue and execute proposals
    /// @param votingDelay_ Number of blocks to wait after proposal creation before voting starts
    /// @param votingPeriod_ Number of blocks the proposal is open for voting
    /// @param proposalThreshold_ Minimum number of votes required to create a proposal
    function initialize(
        IERC20Votes token,
        TimelockControllerUpgradeable timelock,
        uint256 votingDelay_,
        uint256 votingPeriod_,
        uint256 proposalThreshold_
    ) public initializer {
        __Governor_init("TUT Governor");
        __GovernorSettings_init(votingDelay_, votingPeriod_, proposalThreshold_);
        __GovernorVotes_init(token);
        __GovernorTimelockControl_init(timelock);
    }

    // -------------------------------------------------------------------------
    // Governor overrides
    // -------------------------------------------------------------------------

    /// @notice Returns the delay in blocks before voting on a proposal can begin.
    function votingDelay() public view override(GovernorUpgradeable, GovernorSettingsUpgradeable) returns (uint256) {
        return super.votingDelay();
    }

    /// @notice Returns the duration in blocks of the voting period.
    function votingPeriod() public view override(GovernorUpgradeable, GovernorSettingsUpgradeable) returns (uint256) {
        return super.votingPeriod();
    }

    /// @notice Returns the quorum required for a proposal to pass. For the TUT DAO,
    ///         this is set to 4% of the total token supply at the block when the
    ///         proposal is evaluated. Adjust the numerator to change quorum.
    /// @param blockNumber The block number at which to calculate the quorum
    function quorum(uint256 blockNumber) public view override returns (uint256) {
        // 4% quorum: (total supply * 4) / 100
        return (token.getPastTotalSupply(blockNumber) * 4) / 100;
    }

    /// @notice Returns the minimum number of votes required to create a proposal.
    function proposalThreshold() public view override(GovernorUpgradeable, GovernorSettingsUpgradeable) returns (uint256) {
        return super.proposalThreshold();
    }

    // The functions below are required by Solidity because multiple base classes
    // implement the same function. They simply forward to the most specific
    // implementation.

    function state(uint256 proposalId)
        public
        view
        override(GovernorUpgradeable, GovernorTimelockControlUpgradeable)
        returns (ProposalState)
    {
        return super.state(proposalId);
    }

    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public override(GovernorUpgradeable, IGovernorUpgradeable) returns (uint256) {
        return super.propose(targets, values, calldatas, description);
    }

    function _execute(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(GovernorUpgradeable, GovernorTimelockControlUpgradeable) {
        super._execute(proposalId, targets, values, calldatas, descriptionHash);
    }

    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(GovernorUpgradeable, GovernorTimelockControlUpgradeable) returns (uint256) {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    function _executor() internal view override(GovernorUpgradeable, GovernorTimelockControlUpgradeable) returns (address) {
        return super._executor();
    }

    // solhint-disable-next-line comprehensive-interface
    function supportsInterface(bytes4 interfaceId) public view override(GovernorUpgradeable, GovernorTimelockControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}