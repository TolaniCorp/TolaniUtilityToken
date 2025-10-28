// SPDX-License-Identifier: MIT
// Pin the compiler version to avoid floating pragmas and unexpected behaviour.
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/// @title TUTHybridPayrollV2
/// @notice A hybrid payroll contract that allows both scheduled paydays and
/// early advances. Employers register employees with a fixed salary and pay
/// interval, along with maximum advance and minimum payout fractions. Employees
/// can claim earnings prorated by time and optionally draw down a portion of
/// their salary before the end of a pay period. At the end of each interval,
/// employees may claim the remainder of their salary. If advances exceed the
/// completed interval’s earnings, the surplus carries forward into the next
/// interval and a minimum portion of the salary is still paid on payday. The
/// contract uses upgradeable patterns and role‑based access control. This
/// version adds support for automatic treasury top‑ups to maintain
/// sufficient contract balance for payments.
contract TUTHybridPayrollV2 is Initializable, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    bytes32 public constant EMPLOYER_ROLE = keccak256("EMPLOYER_ROLE");

    struct Employee {
        uint256 salary;              // tokens per interval
        uint256 interval;            // pay interval in seconds
        uint256 lastPaid;            // timestamp of last full payout (scheduled)
        uint256 lastAdvanceInterval; // timestamp marking the start of the current advance interval
        uint256 advanceClaimed;      // amount already claimed in current advance interval
        uint256 maxAdvanceFraction;  // max advance per interval in basis points (1e4 = 100%)
        uint256 minPayoutFraction;   // minimum fraction to always pay at payday (basis points)
        bool exists;
    }

    IERC20Upgradeable public token;
    mapping(address => Employee) public employees;
    uint256 public totalCommitment;

    // Treasury address that can top up the contract when funds are low. Must
    // approve this contract for transfers. Only EMPLOYER_ROLE can set.
    address public treasury;
    // Minimum balance the contract tries to maintain after payouts. Only
    // EMPLOYER_ROLE can set.
    uint256 public minBalance;

    event EmployeeAdded(address indexed account, uint256 salary, uint256 interval, uint256 maxAdvance, uint256 minPayout);
    event EmployeeRemoved(address indexed account);
    event SalaryUpdated(address indexed account, uint256 oldSalary, uint256 newSalary);
    event AdvancePaid(address indexed account, uint256 amount);
    event Payday(address indexed account, uint256 amount);
    event MinPayoutUpdated(address indexed account, uint256 oldFraction, uint256 newFraction);
    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);
    event MinBalanceUpdated(uint256 oldMinBalance, uint256 newMinBalance);
    event AutoTopUp(uint256 amount, uint256 newBalance);

    /// @dev Initializes the payroll with a TUT token and admin. Grants EMPLOYER_ROLE to admin.
    function initialize(address tokenAddress, address admin) external initializer {
        require(tokenAddress != address(0), "Invalid token");
        require(admin != address(0), "Invalid admin");
        __AccessControl_init();
        __ReentrancyGuard_init();
        token = IERC20Upgradeable(tokenAddress);
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(EMPLOYER_ROLE, admin);
        // Default minBalance = 0; treasury remains unset until configured
    }

    /// @notice Configure the treasury address used for automatic top‑ups. Only EMPLOYER_ROLE can call.
    /// The treasury must approve this contract for transfers to allow automatic top‑ups.
    function setTreasury(address newTreasury) external onlyRole(EMPLOYER_ROLE) {
        require(newTreasury != address(0), "Invalid treasury");
        address old = treasury;
        treasury = newTreasury;
        emit TreasuryUpdated(old, newTreasury);
    }

    /// @notice Set the minimum balance threshold. The contract will attempt to maintain this balance
    /// after processing payouts. Only EMPLOYER_ROLE can call.
    function setMinBalance(uint256 newMinBalance) external onlyRole(EMPLOYER_ROLE) {
        uint256 old = minBalance;
        minBalance = newMinBalance;
        emit MinBalanceUpdated(old, newMinBalance);
    }

    /// @notice Add an employee with a salary, interval, max advance fraction and min payout fraction. Only employers can call.
    /// @param account The employee address
    /// @param salary Amount of tokens paid per interval
    /// @param interval Duration of one pay period in seconds
    /// @param maxAdvanceFraction Maximum fraction (basis points) of salary that can be taken as an advance each period
    /// @param minPayoutFraction Minimum fraction (basis points) of salary to pay at payday even if advances exceed accrual
    function addEmployee(
        address account,
        uint256 salary,
        uint256 interval,
        uint256 maxAdvanceFraction,
        uint256 minPayoutFraction
    ) external onlyRole(EMPLOYER_ROLE) {
        require(account != address(0), "Invalid account");
        require(!employees[account].exists, "Already exists");
        require(salary > 0 && interval > 0, "Invalid salary or interval");
        // maxAdvanceFraction cannot exceed 10000 (100%). minPayoutFraction cannot exceed 10000.
        require(maxAdvanceFraction <= 10000, "Advance fraction too high");
        require(minPayoutFraction <= 10000, "Min payout fraction too high");
        employees[account] = Employee({
            salary: salary,
            interval: interval,
            lastPaid: block.timestamp,
            lastAdvanceInterval: block.timestamp,
            advanceClaimed: 0,
            maxAdvanceFraction: maxAdvanceFraction,
            minPayoutFraction: minPayoutFraction,
            exists: true
        });
        totalCommitment += salary;
        emit EmployeeAdded(account, salary, interval, maxAdvanceFraction, minPayoutFraction);
    }

    /// @notice Remove an employee. Remaining accrued salary remains claimable via payday.
    function removeEmployee(address account) external onlyRole(EMPLOYER_ROLE) {
        Employee storage e = employees[account];
        require(e.exists, "Not an employee");
        totalCommitment -= e.salary;
        delete employees[account];
        emit EmployeeRemoved(account);
    }

    /// @notice Update salary for an employee. Only employers can call.
    function updateSalary(address account, uint256 newSalary) external onlyRole(EMPLOYER_ROLE) {
        Employee storage e = employees[account];
        require(e.exists, "Not an employee");
        require(newSalary > 0, "Invalid salary");
        uint256 old = e.salary;
        totalCommitment = totalCommitment - old + newSalary;
        e.salary = newSalary;
        emit SalaryUpdated(account, old, newSalary);
    }

    /// @notice Employers can update the minimum payout fraction for an employee. Cannot exceed 100%.
    function updateMinPayoutFraction(address account, uint256 newFraction) external onlyRole(EMPLOYER_ROLE) {
        Employee storage e = employees[account];
        require(e.exists, "Not an employee");
        require(newFraction <= 10000, "Min payout fraction too high");
        uint256 old = e.minPayoutFraction;
        e.minPayoutFraction = newFraction;
        emit MinPayoutUpdated(account, old, newFraction);
    }

    /// @notice Employer deposits TUT tokens to fund payroll obligations.
    function deposit(uint256 amount) external onlyRole(EMPLOYER_ROLE) {
        require(amount > 0, "No deposit");
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
    }

    /// @notice Employees can claim an advance on their earnings up to the configured limit.
    /// Advances reduce the remaining amount available on payday. Uses non‑reentrancy guard.
    /// @param amount The amount of tokens to withdraw as an advance
    function claimAdvance(uint256 amount) external nonReentrant {
        Employee storage e = employees[msg.sender];
        require(e.exists, "Not an employee");
        require(amount > 0, "Nothing to claim");
        // Reset advanceClaimed if a new pay interval has started since the last advance interval.
        uint256 elapsedAdvance = block.timestamp - e.lastAdvanceInterval;
        if (elapsedAdvance >= e.interval) {
            uint256 passed = elapsedAdvance / e.interval;
            e.lastAdvanceInterval += passed * e.interval;
            e.advanceClaimed = 0;
            elapsedAdvance = block.timestamp - e.lastAdvanceInterval;
        }
        uint256 earned = (e.salary * elapsedAdvance) / e.interval;
        uint256 maxAdvance = (e.salary * e.maxAdvanceFraction) / 10000;
        uint256 availableFromAdvanceLimit = maxAdvance > e.advanceClaimed ? maxAdvance - e.advanceClaimed : 0;
        uint256 availableFromEarned = earned > e.advanceClaimed ? earned - e.advanceClaimed : 0;
        uint256 allowed = availableFromAdvanceLimit < availableFromEarned ? availableFromAdvanceLimit : availableFromEarned;
        require(amount <= allowed, "Exceeds advance allowance");
        e.advanceClaimed += amount;
        // Auto top‑up if contract balance is insufficient for this payment
        _autoTopUpIfNeeded(amount);
        require(token.transfer(msg.sender, amount), "Transfer failed");
        emit AdvancePaid(msg.sender, amount);
    }

    /// @notice Employees call this on or after their scheduled payday to receive
    /// their remaining salary for completed intervals. This function pays all
    /// outstanding intervals and resets advance counters. Uses non‑reentrancy guard.
    function claimPayday() external nonReentrant {
        Employee storage e = employees[msg.sender];
        require(e.exists, "Not an employee");
        uint256 elapsed = block.timestamp - e.lastPaid;
        uint256 intervals = elapsed / e.interval;
        require(intervals > 0, "No payday yet");
        // Amount owed for complete intervals
        uint256 owedFull = intervals * e.salary;
        // Determine deduction from advances
        uint256 deduction = e.advanceClaimed;
        // Ensure at least a minimum portion of the salary is paid
        uint256 minPayout = (owedFull * e.minPayoutFraction) / 10000;
        // Cap deduction to ensure payout >= minPayout
        uint256 maxDeduction = owedFull > minPayout ? owedFull - minPayout : 0;
        uint256 leftover = 0;
        if (deduction > maxDeduction) {
            leftover = deduction - maxDeduction;
            deduction = maxDeduction;
        }
        uint256 payout = owedFull - deduction;
        // Move lastPaid forward by the completed intervals
        e.lastPaid += intervals * e.interval;
        // Start a new advance period at lastPaid
        e.lastAdvanceInterval = e.lastPaid;
        // Set advanceClaimed to any leftover amount so it applies to the next interval
        e.advanceClaimed = leftover;
        // Auto top‑up if contract balance is insufficient for this payout
        _autoTopUpIfNeeded(payout);
        require(token.transfer(msg.sender, payout), "Payment failed");
        emit Payday(msg.sender, payout);
    }

    /// @notice View how much an employee has earned since their last full payday.
    /// Includes prorated earnings but does not subtract advances. Use this to
    /// preview available advanceable tokens and upcoming salary.
    function getAccrued(address account) external view returns (uint256) {
        Employee storage e = employees[account];
        if (!e.exists) return 0;
        uint256 elapsed = block.timestamp - e.lastPaid;
        return (e.salary * elapsed) / e.interval;
    }

    /// @notice View the remaining advance available to the employee in the current interval.
    function getAvailableAdvance(address account) external view returns (uint256) {
        Employee storage e = employees[account];
        if (!e.exists) return 0;
        // Reset logic is not applied in view function; compute based on current advance interval
        uint256 elapsedAdvance = block.timestamp - e.lastAdvanceInterval;
        if (elapsedAdvance > e.interval) {
            elapsedAdvance = e.interval;
        }
        uint256 earned = (e.salary * elapsedAdvance) / e.interval;
        uint256 maxAdvance = (e.salary * e.maxAdvanceFraction) / 10000;
        uint256 availableFromAdvanceLimit = maxAdvance > e.advanceClaimed ? maxAdvance - e.advanceClaimed : 0;
        uint256 availableFromEarned = earned > e.advanceClaimed ? earned - e.advanceClaimed : 0;
        return availableFromAdvanceLimit < availableFromEarned ? availableFromAdvanceLimit : availableFromEarned;
    }

    /// @dev Internal function to top up the contract balance from the treasury when needed.
    /// It calculates the desired balance as current balance minus the requested payout amount
    /// plus the configured minBalance. If the current balance is insufficient, it will
    /// transfer the difference from the treasury.  The treasury must have granted
    /// allowance to this contract for the top‑up to succeed.
    function _autoTopUpIfNeeded(uint256 payoutAmount) internal {
        // If no treasury configured or minBalance is zero, skip auto top‑up logic. Payout
        // will revert if insufficient funds.
        if (treasury == address(0)) {
            return;
        }
        uint256 currentBalance = token.balanceOf(address(this));
        // Desired balance = payoutAmount + minBalance. We want to have enough for
        // the payout and maintain minBalance after the payout.
        uint256 desiredBalance = payoutAmount + minBalance;
        if (currentBalance < desiredBalance) {
            uint256 needed = desiredBalance - currentBalance;
            require(token.transferFrom(treasury, address(this), needed), "Top up failed");
            emit AutoTopUp(needed, currentBalance + needed);
        }
    }
}