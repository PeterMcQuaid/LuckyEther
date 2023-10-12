// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/**
 * @title Interface for the "PauserRegistry" contract
 * @author Peter Raymond McQuaid
 * @dev First 3 functions below are getters, to ensure a contract that inherits this
 * interface will implement getters
 */
interface IPauserRegistry {
    event PauserStatusChanged(address indexed pauser, bool canPause);

    event UnpauserStatusChanged(address indexed unpauser, bool canUnpause);

    event RegistryOwnerChanged(address previousRegistryOwner, address newRegistryOwner);

    /// @notice Mapping of pauser address to their pausing status
    function isPauser(address pauser) external view returns (bool);

    /// @notice Mapping of unpauser address to their unpausing status
    function isUnpauser(address unpauser) external view returns (bool);

    /**
     * @notice Returns owner of registry, who has sole power to update registry address,
     * as well as set and unset pausers and unpausers
     * @dev "registryOwner" is initialized as deployer (msg.sender)
     */
    function registryOwner() external view returns (address); 

    /**
     * @notice Updates pauser status for "pauser"
     * @dev Should only be callable by current owner 
     */
    function updatePauser(address pauser, bool canPause) external;

    /**
     * @notice Updates unpauser status for "unpauser"
     * @dev Should only be callable by current owner 
     */
    function updateUnpauser(address unpauser, bool canUnpause) external;

    /**
     * @notice Updates the registry owner
     * @dev Should only be callable by current owner 
     */ 
    function updateRegistryOwner(address newRegistryOwner) external;
}