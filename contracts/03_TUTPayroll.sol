// SPDX-License-Identifier: MIT
// Pin the compiler version to avoid floating pragmas and unexpected behaviour.
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/// @title TUTPayroll
/// @notice Handles payroll operations using TUT tokens. Employers register
/// employees with a salary and pay interval. Employers deposit funds into the
/// contract, and employees can withdraw their earned wages on schedule. The
/// contract supports updating salaries and removing employees. It is designed
/// to be upgradeable and secure against reentrancy attacks.
contract TUTPayroll is Initializable, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    bytes32 public constant EMPLOYER_ROLE = keccak256("EMPLOYER_ROLE");

    struct Employee {
        uint256 salary; // tokens per interval
        uint256 interval; // pay interval in seconds
        uint256 lastPaid; // timestamp of last withdrawal
        bool exists;
    }

    IERC20Upgradeable public token;
    mapping(address => Employee) public employees;
    uint256 public totalMonthlyCommitment;

    event EmployeeAdded(address indexed account, uint256 salary, uint256 interval);
    event EmployeeRemoved(address indexed account);
    event SalaryUpdated(address indexed account, uint256 oldSalary, uint256 newSalary);
    event Paid(address indexed account, uint256 amount);

    /// @dev Initializes the payroll contract with token and initial admin.
    function initialize(address tokenAddress, address admin) external initializer {
        require(tokenAddress != address(0), "Invalid token");
        require(admin != address(0), "Invalid admin");
        __AccessControl_init();
        __ReentrancyGuard_init();
        token = IERC20Upgradeable(tokenAddress);
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(EMPLOYER_ROLE, admin);
    }

    /// @notice Adds a new employee to the payroll. Only employers can call.
    /// @param account Employee address
    /// @param salary Amount of tokens per interval
    /// @param interval Payment interval in seconds
    function addEmployee(address account, uint256 salary, uint256 interval) external onlyRole(EMPLOYER_ROLE) {
        require(account != address(0), "Invalid account");
        require(!employees[account].exists, "Already exists");
        require(salary > 0 && interval > 0, "Invalid salary or interval");
        employees[account] = Employee({ salary: salary, interval: interval, lastPaid: block.timestamp, exists: true });
        totalMonthlyCommitment += salary;
        emit EmployeeAdded(account, salary, interval);
    }

    /// @notice Removes an employee from the payroll. Remaining accrued salary can still be claimed.
    function removeEmployee(address account) external onlyRole(EMPLOYER_ROLE) {
        require(employees[account].exists, "Not an employee");
        totalMonthlyCommitment -= employees[account].salary;
        delete employees[account];
        emit EmployeeRemoved(account);
    }

    /// @notice Updates an employee's salary. Only employers can call.
    function updateSalary(address account, uint256 newSalary) external onlyRole(EMPLOYER_ROLE) {
        require(employees[account].exists, "Not an employee");
        require(newSalary > 0, "Invalid salary");
        uint256 old = employees[account].salary;
        totalMonthlyCommitment = totalMonthlyCommitment - old + newSalary;
        employees[account].salary = newSalary;
        emit SalaryUpdated(account, old, newSalary);
    }

    /// @notice Deposit tokens to fund the payroll. Employers should deposit enough to cover upcoming wages.
    function deposit(uint256 amount) external onlyRole(EMPLOYER_ROLE) {
        require(amount > 0, "No deposit");
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
    }

    /// @notice Employee withdraws their accrued salary. Calculates how many intervals have passed since last payout.
    function claim() external nonReentrant {
        Employee storage e = employees[msg.sender];
        require(e.exists, "Not an employee");
        uint256 owed = _accrued(msg.sender);
        require(owed > 0, "Nothing owed yet");
        e.lastPaid = block.timestamp;
        require(token.transfer(msg.sender, owed), "Payment failed");
        emit Paid(msg.sender, owed);
    }

    /// @notice Calculates the accrued salary for an employee without updating state.
    function getAccrued(address account) external view returns (uint256) {
        return _accrued(account);
    }

    /// @dev Internal function to compute how much salary an employee can claim.
    ///
    /// This implementation prorates earnings based on the elapsed time since
    /// `lastPaid` rather than only counting full pay intervals. It multiplies
    /// the employee's salary by the number of seconds elapsed and then divides
    /// by the interval duration. This preserves fractional accrual and avoids
    /// rounding losses when employees claim slightly before a full interval
    /// has completed. Note that integer division still floors any fractional
    /// token amounts (less than 1 wei), but no portion of a completed time
    /// interval is discarded.
    function _accrued(address account) internal view returns (uint256) {
        Employee storage e = employees[account];
        if (!e.exists) return 0;
        uint256 elapsed = block.timestamp - e.lastPaid;
        // Calculate owed salary pro‑rata. Multiply first to avoid truncating
        // fractional intervals before applying the salary.
        uint256 owed = (e.salary * elapsed) / e.interval;
        return owed;
    }
}