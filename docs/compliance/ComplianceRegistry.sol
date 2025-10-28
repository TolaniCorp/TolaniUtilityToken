// SPDX-License-Identifier: MIT
// Fix compiler version to avoid floating pragma.
pragma solidity 0.8.20;

/**
 * @title ComplianceRegistry
 * @dev Register participants and manage compliance tasks. A compliance officer can
 *      register new participants and create tasks. Participants can update
 *      their own tasks, while officers can update any task. Task status
 *      transitions between Pending, Approved, and Rejected.
 */
import "@openzeppelin/contracts/access/AccessControl.sol";

contract ComplianceRegistry is AccessControl {
    bytes32 public constant COMPLIANCE_OFFICER_ROLE = keccak256("COMPLIANCE_OFFICER_ROLE");
    bytes32 public constant PARTICIPANT_ROLE = keccak256("PARTICIPANT_ROLE");

    enum Status { Pending, Approved, Rejected }

    struct Task {
        string description;
        Status status;
    }

    // Participants that have been registered
    mapping(address => bool) public registered;
    // Mapping of participant to an array of compliance tasks
    mapping(address => Task[]) public tasks;

    event ParticipantRegistered(address indexed participant);
    event TaskCreated(address indexed participant, string description);
    event TaskStatusUpdated(address indexed participant, uint256 index, Status status);

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(COMPLIANCE_OFFICER_ROLE, admin);
    }

    /**
     * @dev Register a new participant. Grants them the participant role.
     * @param participant The address of the participant to register
     */
    function registerParticipant(address participant) external onlyRole(COMPLIANCE_OFFICER_ROLE) {
        require(!registered[participant], "Already registered");
        registered[participant] = true;
        _grantRole(PARTICIPANT_ROLE, participant);
        emit ParticipantRegistered(participant);
    }

    /**
     * @dev Create a new compliance task for a participant.
     * @param participant The address of the participant
     * @param description A description of the compliance task
     */
    function createTask(address participant, string memory description) external onlyRole(COMPLIANCE_OFFICER_ROLE) {
        require(registered[participant], "Not registered");
        tasks[participant].push(Task({ description: description, status: Status.Pending }));
        emit TaskCreated(participant, description);
    }

    /**
     * @dev Update the status of a compliance task. Officers can update any
     *      participant's tasks; participants can only update their own.
     * @param participant The participant owning the task
     * @param index The index of the task in the participant's task array
     * @param status The new status to set
     */
    function updateTaskStatus(address participant, uint256 index, Status status) external {
        require(hasRole(COMPLIANCE_OFFICER_ROLE, msg.sender) || (hasRole(PARTICIPANT_ROLE, msg.sender) && msg.sender == participant), "Not authorized");
        require(index < tasks[participant].length, "Invalid index");
        tasks[participant][index].status = status;
        emit TaskStatusUpdated(participant, index, status);
    }

    /**
     * @dev Get all tasks for a participant.
     * @param participant The address of the participant
     */
    function getTasks(address participant) external view returns (Task[] memory) {
        return tasks[participant];
    }
}