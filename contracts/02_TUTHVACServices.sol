// SPDX-License-Identifier: MIT
// Use a fixed Solidity version to ensure deterministic compilation.
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/// @title TUTHVACServices
/// @notice Manages HVAC service orders with escrowed payments. Customers create
/// service requests, deposit TUT tokens, and assign technicians. Technicians
/// perform work, mark completion, and receive payment once the customer
/// confirms. Includes cancellation and rating features.
contract TUTHVACServices is Initializable, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant TECHNICIAN_ROLE = keccak256("TECHNICIAN_ROLE");

    enum Status { Created, Assigned, InProgress, Completed, Cancelled }

    struct Order {
        address customer;
        address technician;
        uint256 deposit;
        Status status;
        string description;
        uint256 rating; // 0-5 star rating from customer
        uint256 createdAt;
    }

    /// @notice ERC20 token used for deposits and payments
    IERC20Upgradeable public token;
    /// @dev Mapping order id to order details
    mapping(uint256 => Order) public orders;
    uint256 public nextOrderId;

    event OrderCreated(uint256 indexed orderId, address indexed customer, uint256 deposit, string description);
    event OrderAssigned(uint256 indexed orderId, address indexed technician);
    event OrderStarted(uint256 indexed orderId);
    event OrderCompleted(uint256 indexed orderId);
    event OrderCancelled(uint256 indexed orderId);
    event OrderRated(uint256 indexed orderId, uint256 rating);

    /// @dev Initializes the contract with the token address and sets up roles. Only run once.
    function initialize(address tokenAddress, address manager) external initializer {
        require(tokenAddress != address(0), "Invalid token");
        require(manager != address(0), "Invalid manager");
        __AccessControl_init();
        __ReentrancyGuard_init();
        token = IERC20Upgradeable(tokenAddress);
        _grantRole(DEFAULT_ADMIN_ROLE, manager);
        _grantRole(MANAGER_ROLE, manager);
    }

    /// @notice Managers can register a technician by granting them the TECHNICIAN_ROLE.
    function registerTechnician(address technician) external onlyRole(MANAGER_ROLE) {
        require(technician != address(0), "Invalid technician");
        _grantRole(TECHNICIAN_ROLE, technician);
    }

    /// @notice Customer creates a work order with a deposit. Requires prior token approval.
    function createOrder(uint256 deposit, string calldata description) external nonReentrant returns (uint256 orderId) {
        require(deposit > 0, "Deposit must be > 0");
        orderId = nextOrderId++;
        orders[orderId] = Order({
            customer: msg.sender,
            technician: address(0),
            deposit: deposit,
            status: Status.Created,
            description: description,
            rating: 0,
            createdAt: block.timestamp
        });
        require(token.transferFrom(msg.sender, address(this), deposit), "Deposit transfer failed");
        emit OrderCreated(orderId, msg.sender, deposit, description);
    }

    /// @notice Manager assigns a technician to an order.
    function assignTechnician(uint256 orderId, address technician) external onlyRole(MANAGER_ROLE) {
        Order storage o = orders[orderId];
        require(o.status == Status.Created, "Order not assignable");
        require(hasRole(TECHNICIAN_ROLE, technician), "Not a technician");
        o.technician = technician;
        o.status = Status.Assigned;
        emit OrderAssigned(orderId, technician);
    }

    /// @notice Technician starts work on an assigned order.
    function startWork(uint256 orderId) external {
        Order storage o = orders[orderId];
        require(o.status == Status.Assigned, "Order not ready");
        require(o.technician == msg.sender, "Not assigned technician");
        o.status = Status.InProgress;
        emit OrderStarted(orderId);
    }

    /// @notice Technician marks work as completed. Customer must confirm to release payment.
    function markCompleted(uint256 orderId) external {
        Order storage o = orders[orderId];
        require(o.status == Status.InProgress, "Order not in progress");
        require(o.technician == msg.sender, "Not assigned technician");
        o.status = Status.Completed;
        emit OrderCompleted(orderId);
    }

    /// @notice Customer confirms completion and releases payment to technician. Emits rating event if provided.
    function confirmAndRate(uint256 orderId, uint256 rating) external nonReentrant {
        require(rating <= 5, "Rating must be 0-5");
        Order storage o = orders[orderId];
        require(o.status == Status.Completed, "Order not completed");
        require(o.customer == msg.sender, "Not your order");
        o.status = Status.Cancelled; // Use Cancelled state to represent paid and closed
        o.rating = rating;
        require(token.transfer(o.technician, o.deposit), "Payment transfer failed");
        emit OrderRated(orderId, rating);
    }

    /// @notice Customer can cancel an order before work starts and retrieve deposit.
    function cancelOrder(uint256 orderId) external nonReentrant {
        Order storage o = orders[orderId];
        require(o.customer == msg.sender, "Not your order");
        require(o.status == Status.Created || o.status == Status.Assigned, "Cannot cancel now");
        o.status = Status.Cancelled;
        require(token.transfer(o.customer, o.deposit), "Refund failed");
        emit OrderCancelled(orderId);
    }

    /// @notice Manager can refund deposit to customer in case of dispute. Only before completion.
    function managerRefund(uint256 orderId) external onlyRole(MANAGER_ROLE) nonReentrant {
        Order storage o = orders[orderId];
        require(o.status == Status.Assigned || o.status == Status.InProgress, "Cannot refund");
        o.status = Status.Cancelled;
        require(token.transfer(o.customer, o.deposit), "Refund failed");
        emit OrderCancelled(orderId);
    }
}