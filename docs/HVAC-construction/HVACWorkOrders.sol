// SPDX-License-Identifier: MIT
// Fix compiler version to avoid floating pragma.
pragma solidity 0.8.20;

/**
 * @title HVACWorkOrders
 * @dev Manage work orders for HVAC and construction tasks. Managers can create
 *      work orders and assign technicians. Technicians and managers can update
 *      the order status as the job progresses. Uses role‑based access control
 *      to restrict actions to the appropriate personnel.
 */
import "@openzeppelin/contracts/access/AccessControl.sol";

contract HVACWorkOrders is AccessControl {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant TECHNICIAN_ROLE = keccak256("TECHNICIAN_ROLE");

    enum Status { Created, Assigned, InProgress, Completed, Cancelled }

    struct WorkOrder {
        uint256 id;
        string description;
        address assignedTo;
        Status status;
        uint256 createdAt;
        uint256 updatedAt;
    }

    uint256 private _nextId;
    mapping(uint256 => WorkOrder) private _orders;

    event WorkOrderCreated(uint256 indexed id, string description);
    event TechnicianAssigned(uint256 indexed id, address indexed technician);
    event StatusUpdated(uint256 indexed id, Status status);

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MANAGER_ROLE, admin);
    }

    /**
     * @dev Create a new work order. Only accounts with the manager role may
     *      call this function.
     * @param description A short description of the work required
     */
    function createWorkOrder(string memory description) external onlyRole(MANAGER_ROLE) {
        uint256 id = ++_nextId;
        _orders[id] = WorkOrder({
            id: id,
            description: description,
            assignedTo: address(0),
            status: Status.Created,
            createdAt: block.timestamp,
            updatedAt: block.timestamp
        });
        emit WorkOrderCreated(id, description);
    }

    /**
     * @dev Assign a technician to an existing work order. Only managers can
     *      assign technicians. Assigning will set the status to `Assigned`.
     * @param id The work order identifier
     * @param technician The technician address
     */
    function assignTechnician(uint256 id, address technician) external onlyRole(MANAGER_ROLE) {
        WorkOrder storage order = _orders[id];
        require(order.id != 0, "Order not found");
        require(order.status == Status.Created || order.status == Status.Assigned, "Cannot assign");
        order.assignedTo = technician;
        order.status = Status.Assigned;
        order.updatedAt = block.timestamp;
        _grantRole(TECHNICIAN_ROLE, technician);
        emit TechnicianAssigned(id, technician);
    }

    /**
     * @dev Update the status of a work order. Technicians can mark their own
     *      orders as `InProgress` or `Completed`. Managers can cancel or
     *      override status. Timestamp is updated on each change.
     * @param id The work order identifier
     * @param status The new status
     */
    function updateStatus(uint256 id, Status status) external {
        WorkOrder storage order = _orders[id];
        require(order.id != 0, "Order not found");
        if (status == Status.InProgress || status == Status.Completed) {
            require(hasRole(TECHNICIAN_ROLE, msg.sender), "Not technician");
            require(order.assignedTo == msg.sender, "Not assigned");
        } else {
            require(hasRole(MANAGER_ROLE, msg.sender), "Not manager");
        }
        order.status = status;
        order.updatedAt = block.timestamp;
        emit StatusUpdated(id, status);
    }

    /**
     * @dev Get a work order by its identifier.
     * @param id The work order identifier
     */
    function getOrder(uint256 id) external view returns (WorkOrder memory) {
        return _orders[id];
    }
}