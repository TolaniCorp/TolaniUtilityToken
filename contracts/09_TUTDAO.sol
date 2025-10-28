// SPDX-License-Identifier: MIT
// Use a fixed Solidity version to ensure deterministic compilation.
pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Votes.sol";

/// @title TUTDAO
/// @notice A lightweight on‑chain governance contract for the Tolani Utility Token (TUT).
///         This DAO enables token holders to create proposals, vote on them, and execute
///         decisions based on the collective outcome. Voting weight is derived from the
///         ERC20Votes extension which captures historical voting power via checkpoints.
///         The contract is upgradeable and uses role‑based access control for admin
///         functions. It intentionally avoids integrating a timelock or complex
///         execution logic, leaving those features to be implemented at a higher
///         governance layer (e.g. a Gnosis Safe with a timelock module).
///
/// @dev The DAO contract is upgradeable via OpenZeppelin proxies. Functions such as
///      setting the voting period are restricted to the ADMIN_ROLE. Proposals can
///      execute arbitrary off‑chain actions by emitting an event; to perform on‑chain
///      executions, extend the `executeProposal` function to call external contracts.
contract TUTDAO is Initializable, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    /// @dev Role for administrative functions (setting parameters, emergency stops, etc.)
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    /// @dev Reference to the ERC20Votes token used for voting. This interface exposes
    ///      `getPastVotes` for historical snapshots. The actual token contract must
    ///      implement ERC20Votes (or the upgradeable variant).
    IERC20Votes public token;

    /// @dev Voting period in seconds. Proposals remain open for this long from the
    ///      moment of creation. Defaults to one week (7 * 24 * 3600 seconds) but can
    ///      be adjusted by an admin via `setVotingPeriod`.
    uint256 public votingPeriod;

    struct Proposal {
        address proposer;
        string description;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 deadline;
        bool executed;
    }

    /// @dev Dynamic array of proposals. Each proposal is referenced by its index.
    Proposal[] private _proposals;

    /// @dev Tracks whether a given address has voted on a particular proposal. This
    ///      prevents double voting. Mapping: proposalId => voter => voted.
    mapping(uint256 => mapping(address => bool)) private _hasVoted;

    /// Events emitted during DAO operation.
    event ProposalCreated(uint256 indexed id, address indexed proposer, string description, uint256 deadline);
    event Voted(uint256 indexed id, address indexed voter, bool support, uint256 weight);
    event Executed(uint256 indexed id);
    event VotingPeriodChanged(uint256 oldPeriod, uint256 newPeriod);

    /// @notice Initializes the DAO with a voting token and admin. Grants the
    ///         ADMIN_ROLE to the provided admin address. Voting period defaults
    ///         to one week.
    /// @param tokenAddress The address of the ERC20Votes token used for voting power
    /// @param admin The administrator address who receives the ADMIN_ROLE
    function initialize(address tokenAddress, address admin) external initializer {
        require(tokenAddress != address(0), "Invalid token");
        require(admin != address(0), "Invalid admin");
        __AccessControl_init();
        __ReentrancyGuard_init();
        token = IERC20Votes(tokenAddress);
        votingPeriod = 7 days;
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
    }

    // -------------------------------------------------------------------------
    // Proposal creation and voting
    // -------------------------------------------------------------------------

    /// @notice Create a new governance proposal. Any address with non‑zero
    ///         voting power (current token balance) may propose. The proposal will
    ///         remain open for voting until `block.timestamp + votingPeriod`.
    /// @param description A human‑readable description of the proposal
    /// @return id The index of the newly created proposal
    function createProposal(string memory description) external returns (uint256 id) {
        require(token.balanceOf(msg.sender) > 0, "No voting power");
        id = _proposals.length;
        _proposals.push(Proposal({
            proposer: msg.sender,
            description: description,
            yesVotes: 0,
            noVotes: 0,
            deadline: block.timestamp + votingPeriod,
            executed: false
        }));
        emit ProposalCreated(id, msg.sender, description, _proposals[id].deadline);
    }

    /// @notice Cast a vote on a proposal. Each address may vote once per proposal.
    /// @dev Uses the ERC20Votes `getPastVotes` mechanism to query the caller's voting
    ///      power at the previous block to avoid flash‑loan manipulation. Requires
    ///      that the voter had tokens when the vote is cast. Voting after the
    ///      deadline is disallowed.
    /// @param id The proposal identifier
    /// @param support True for yes, false for no
    function vote(uint256 id, bool support) external {
        require(id < _proposals.length, "Invalid proposal");
        Proposal storage p = _proposals[id];
        require(block.timestamp < p.deadline, "Voting ended");
        require(!_hasVoted[id][msg.sender], "Already voted");
        uint256 weight = token.getPastVotes(msg.sender, block.number - 1);
        require(weight > 0, "No voting power");
        if (support) {
            p.yesVotes += weight;
        } else {
            p.noVotes += weight;
        }
        _hasVoted[id][msg.sender] = true;
        emit Voted(id, msg.sender, support, weight);
    }

    /// @notice Execute a proposal after voting closes. Only proposals with more yes
    ///         votes than no votes will be considered successful. Execution is
    ///         limited to marking the proposal as executed and emitting an event.
    ///         To perform real actions, extend this function to call external
    ///         contracts or modify state. Anyone may call this once the voting
    ///         period has ended.
    /// @param id The proposal identifier
    function executeProposal(uint256 id) external nonReentrant {
        require(id < _proposals.length, "Invalid proposal");
        Proposal storage p = _proposals[id];
        require(block.timestamp >= p.deadline, "Voting not ended");
        require(!p.executed, "Already executed");
        require(p.yesVotes > p.noVotes, "Proposal rejected");
        p.executed = true;
        // Extend here to perform on‑chain actions using call, delegatecall, etc.
        emit Executed(id);
    }

    // -------------------------------------------------------------------------
    // Admin functions
    // -------------------------------------------------------------------------

    /// @notice Update the voting period for future proposals. Only accounts
    ///         holding the ADMIN_ROLE may call this. The new period must be
    ///         greater than zero to prevent immediate proposal expirations.
    /// @param newPeriod The duration in seconds for which proposals remain open
    function setVotingPeriod(uint256 newPeriod) external onlyRole(ADMIN_ROLE) {
        require(newPeriod > 0, "Invalid period");
        uint256 old = votingPeriod;
        votingPeriod = newPeriod;
        emit VotingPeriodChanged(old, newPeriod);
    }

    /// @notice Returns the total number of proposals created.
    /// @return The number of proposals in the DAO
    function proposalCount() external view returns (uint256) {
        return _proposals.length;
    }

    /// @notice Retrieve details of a proposal by its identifier. Returns the
    ///         entire Proposal struct. Useful for front‑end display.
    /// @param id The proposal identifier
    /// @return The proposal data
    function getProposal(uint256 id) external view returns (Proposal memory) {
        require(id < _proposals.length, "Invalid proposal");
        return _proposals[id];
    }
}