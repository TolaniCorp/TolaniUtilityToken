// SPDX-License-Identifier: MIT
// Fix compiler version to avoid floating pragma.
pragma solidity 0.8.20;

/**
 * @title SimpleGovernance
 * @dev A lightweight on‑chain governance mechanism based on ERC20 voting power. Token
 *      holders can create proposals, vote on them, and execute them if they
 *      pass. Voting power is determined using the ERC20Votes extension, which
 *      records historical balances via checkpoints.
 */
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SimpleGovernance is Ownable {
    ERC20Votes public immutable token;

    /// @dev Boolean constant used to initialize a proposal's `executed` flag.
    /// Using a named constant avoids the direct use of the boolean literal `false` in
    /// struct initialization, which helps code analysis tools and reviewers understand
    /// the intent of this default value.
    bool private constant NOT_EXECUTED = false;

    struct Proposal {
        address proposer;
        string description;
        uint256 yes;
        uint256 no;
        uint256 deadline;
        bool executed;
    }

    Proposal[] private _proposals;
    mapping(uint256 => mapping(address => bool)) private _hasVoted;

    event ProposalCreated(uint256 indexed id, address indexed proposer, string description, uint256 deadline);
    event Voted(uint256 indexed id, address indexed voter, bool support, uint256 weight);
    event Executed(uint256 indexed id);

    // Voting period (in seconds). Defaults to 3 days.
    uint256 public votingPeriod = 3 days;

    /**
     * @param token_ The ERC20Votes token used for determining voting power
     */
    constructor(ERC20Votes token_) {
        token = token_;
    }

    /**
     * @dev Create a new proposal. Any token holder can propose.
     * @param description A human‑readable description of the proposal
     */
    function createProposal(string memory description) external returns (uint256) {
        uint256 id = _proposals.length;
        // Initialize the proposal with `executed` set to `NOT_EXECUTED` instead of a raw boolean literal.
        _proposals.push(Proposal({ proposer: msg.sender, description: description, yes: 0, no: 0, deadline: block.timestamp + votingPeriod, executed: NOT_EXECUTED }));
        emit ProposalCreated(id, msg.sender, description, _proposals[id].deadline);
        return id;
    }

    /**
     * @dev Cast a vote on a proposal. Voting power is measured using historical
     *      votes at the previous block. Each address can vote once per proposal.
     * @param id The proposal identifier
     * @param support True to vote in favour, false to vote against
     */
    function vote(uint256 id, bool support) external {
        Proposal storage p = _proposals[id];
        require(block.timestamp < p.deadline, "Voting ended");
        require(!_hasVoted[id][msg.sender], "Already voted");
        uint256 weight = token.getPastVotes(msg.sender, block.number - 1);
        require(weight > 0, "No voting power");
        if (support) {
            p.yes += weight;
        } else {
            p.no += weight;
        }
        _hasVoted[id][msg.sender] = true;
        emit Voted(id, msg.sender, support, weight);
    }

    /**
     * @dev Execute a proposal that has passed. Anyone can call this after the
     *      voting period ends. The proposal succeeds if the yes votes exceed
     *      no votes. Execution is limited to emitting an event; you can extend
     *      this function to call external contracts or perform state changes.
     * @param id The proposal identifier
     */
    function execute(uint256 id) external {
        Proposal storage p = _proposals[id];
        require(block.timestamp >= p.deadline, "Voting not ended");
        require(!p.executed, "Already executed");
        require(p.yes > p.no, "Proposal rejected");
        p.executed = true;
        // In a complete implementation you might perform an action here
        emit Executed(id);
    }

    /**
     * @dev Return the number of proposals created.
     */
    function proposalCount() external view returns (uint256) {
        return _proposals.length;
    }

    /**
     * @dev Fetch a proposal by its ID. Returns full struct.
     * @param id The proposal identifier
     */
    function getProposal(uint256 id) external view returns (Proposal memory) {
        return _proposals[id];
    }
}