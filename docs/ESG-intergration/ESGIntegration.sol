// SPDX-License-Identifier: MIT
// Fix compiler version to avoid floating pragma.
pragma solidity 0.8.20;

/**
 * @title ESGIntegration
 * @dev Contract for registering projects and tracking ESG metrics. Project managers can
 *      create new projects and add metrics, while metric reporters can update
 *      metric values. Anyone can query a project's metrics. This contract uses
 *      role‑based access control and the EnumerableSet library from OpenZeppelin
 *      to manage metric IDs per project.
 */
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract ESGIntegration is AccessControl {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    bytes32 public constant PROJECT_MANAGER_ROLE = keccak256("PROJECT_MANAGER_ROLE");
    bytes32 public constant METRIC_REPORTER_ROLE = keccak256("METRIC_REPORTER_ROLE");

    struct Metric {
        string id;
        string description;
        uint256 target;
        uint256 current;
    }

    struct Project {
        string id;
        string name;
        bool active;
        EnumerableSet.Bytes32Set metrics;
    }

    // Mapping of metric hash to metric details
    mapping(bytes32 => Metric) public metrics;
    // Mapping of project hash to project details
    mapping(bytes32 => Project) public projects;

    event ProjectRegistered(string projectId, string name);
    event MetricAdded(string projectId, string metricId, string description, uint256 target);
    event MetricReported(string projectId, string metricId, uint256 newValue);

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(PROJECT_MANAGER_ROLE, admin);
        _grantRole(METRIC_REPORTER_ROLE, admin);
    }

    /**
     * @dev Register a new ESG project. The project ID must be unique.
     * @param projectId The external identifier for the project
     * @param name A human‑readable name for the project
     */
    function registerProject(string memory projectId, string memory name) external onlyRole(PROJECT_MANAGER_ROLE) {
        bytes32 key = keccak256(abi.encodePacked(projectId));
        require(bytes(projects[key].id).length == 0, "Project exists");
        projects[key].id = projectId;
        projects[key].name = name;
        projects[key].active = true;
        emit ProjectRegistered(projectId, name);
    }

    /**
     * @dev Add a new metric to a registered project.
     * @param projectId The project identifier
     * @param metricId The unique metric identifier
     * @param description A description of what the metric measures
     * @param target The desired target value for the metric
     */
    function addMetric(
        string memory projectId,
        string memory metricId,
        string memory description,
        uint256 target
    ) external onlyRole(PROJECT_MANAGER_ROLE) {
        bytes32 pKey = keccak256(abi.encodePacked(projectId));
        require(projects[pKey].active, "Project not active");
        bytes32 mKey = keccak256(abi.encodePacked(metricId));
        require(bytes(metrics[mKey].id).length == 0, "Metric exists");
        metrics[mKey] = Metric({ id: metricId, description: description, target: target, current: 0 });
        projects[pKey].metrics.add(mKey);
        emit MetricAdded(projectId, metricId, description, target);
    }

    /**
     * @dev Report a new value for a metric. Only accounts with the reporter role
     *      may call this function.
     * @param projectId The project identifier
     * @param metricId The metric identifier
     * @param newValue The new value to store
     */
    function reportMetric(string memory projectId, string memory metricId, uint256 newValue) external onlyRole(METRIC_REPORTER_ROLE) {
        bytes32 pKey = keccak256(abi.encodePacked(projectId));
        bytes32 mKey = keccak256(abi.encodePacked(metricId));
        require(projects[pKey].active, "Project not active");
        require(bytes(metrics[mKey].id).length != 0, "Metric not found");
        metrics[mKey].current = newValue;
        emit MetricReported(projectId, metricId, newValue);
    }

    /**
     * @dev Return all metrics for a given project. The returned array may be
     *      empty if no metrics have been added. This function copies storage
     *      data into memory; use with care for projects with many metrics.
     * @param projectId The project identifier
     */
    function getProjectMetrics(string memory projectId) external view returns (Metric[] memory) {
        bytes32 pKey = keccak256(abi.encodePacked(projectId));
        uint256 count = projects[pKey].metrics.length();
        Metric[] memory list = new Metric[](count);
        for (uint256 i = 0; i < count; i++) {
            bytes32 mKey = projects[pKey].metrics.at(i);
            list[i] = metrics[mKey];
        }
        return list;
    }
}