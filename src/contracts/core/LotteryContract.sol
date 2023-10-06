// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {IPauserRegistry} from "../interfaces/IPauserRegistry.sol";

/**
 * @title A lottery contract with automated prize payouts
 * @author Peter McQuaid
 * @notice The functionalities of this contract are:
 * - accepting Ether deposits
 * - 
 * 
 * 
 * @dev This implementation contract is both upgradable via the 
 * {TransparentUpgradeableProxy} proxy pattern, and pausable through
 * a pauser registry
 */
contract LotteryContract is Initializable, PausableUpgradeable {

    /// @dev Defines address of external "PauserRegistry" contract
    IPauserRegistry private immutable pauserRegistry;

    /// @notice Exact deposit to enter the lottery raffle
    uint256 private immutable lotteryDeposit;

    constructor() {



        /*
          Prevents "initialize()" from being run in the context 
          of this contract's own storage
        */
        _disableInitializers();
    }

    // EXTERNAL FUNCTIONS

    /**
     * @dev Must be called by owner of "ProxyAdmin" within the "upgradeAndCall()" function via
     * the "bytes memory data" argument, when setting this contract as the implementation
     */
    function initialize() external initializer {}
}