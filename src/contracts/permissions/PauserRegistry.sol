// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IPauserRegistry} from "../interfaces/IPauserRegistry.sol";

/**
 * @title A simple registry contract for pausers/unpausers
 * @author Peter Raymond McQuaid
 * @dev Initial owner set as msg.sender from deploy transaction. Owner has
 * sole control over pauser/unpauser address as well as updating the current owner.
 * An initial list of pausers/unpausers is passed in as a contructor argument
 */
contract PauserRegistry is IPauserRegistry {
    /// @notice Owner of registry
    address public registryOwner;

    /// @notice pauser => status of pauser
    mapping(address => bool) public isPauser;

    /// @notice unpauser => status of unpauser
    mapping(address => bool) public isUnpauser;

    modifier onlyRegistryOwner() {
        require(msg.sender == registryOwner);
        _;
    }

    constructor(address[] memory initialPausers, address[] memory initialUnpausers) {
        registryOwner = msg.sender;

        for (uint256 i = 0; i < initialPausers.length; i++) {
            _updatePauser(initialPausers[i], true);
        }

        for (uint256 i = 0; i < initialUnpausers.length; i++) {
            _updateUnpauser(initialUnpausers[i], true);
        }
    }

    /**
     * @notice Updates pauser status through respective private function "_updatePauser()"
     * @param pauser Address to modify pauser status
     * @param canPause New pauser status for "pauser"
     */
    function updatePauser(address pauser, bool canPause) external onlyRegistryOwner {
        _updatePauser(pauser, canPause);
    }

    /**
     * @notice Updates unpauser status through respective private function "_updateUnpauser()"
     * @param unpauser Address to modify unpauser status
     * @param canUnpause New unpauser status for "pauser"
     */
    function updateUnpauser(address unpauser, bool canUnpause) external onlyRegistryOwner {
        _updateUnpauser(unpauser, canUnpause);
    }

    /**
     * @notice Updates "registryOwner" through respective private function "_updateRegistryOwner()"
     * @param newRegistryOwner New "registryOwner"
     */
    function updateRegistryOwner(address newRegistryOwner) external onlyRegistryOwner {
        _updateRegistryOwner(newRegistryOwner);
    }

    function _updatePauser(address pauser, bool canPause) private {
        isPauser[pauser] = canPause;
        emit PauserStatusChanged(pauser, canPause);
    }

    function _updateUnpauser(address unpauser, bool canUnpause) private {
        isUnpauser[unpauser] = canUnpause;
        emit UnpauserStatusChanged(unpauser, canUnpause);
    }

    function _updateRegistryOwner(address newRegistryOwner) private {
        address previousRegistryOwner = registryOwner;
        registryOwner = newRegistryOwner;
        emit RegistryOwnerChanged(previousRegistryOwner, newRegistryOwner);
    }
}