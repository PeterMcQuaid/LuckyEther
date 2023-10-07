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
 * @dev This implementation contract is upgradable via the 
 * {TransparentUpgradeableProxy} proxy pattern, and pausable through
 * a pauser registry
 */
contract LotteryContract is PausableUpgradeable {

    /// @dev The external "PauserRegistry" contract
    IPauserRegistry private pauserRegistry;

    /// @notice Exact deposit to enter the lottery raffle
    uint256 private immutable lotteryDeposit;

    modifier onlyPauser() {
        require(pauserRegistry.isPauser(msg.sender), "msg.sender is not authorized as a pauser");
        _;
    }

    modifier onlyUnpauser() {
        require(pauserRegistry.isUnpauser(msg.sender), "msg.sender is not authorized as an unpauser");
        _;
    }

    constructor(uint256 _lotteryDeposit) {
        lotteryDeposit = _lotteryDeposit;

        /*
          Prevents "initialize()" from being run in the context 
          of this contract's own storage
        */
        _disableInitializers();
    }

    // EXTERNAL FUNCTIONS

    /**
     * @dev Must be called by owner of "ProxyAdmin" within the "upgradeAndCall()" function via
     * "bytes memory data" argument, when setting this contract as the implementation
     */
    function initialize(IPauserRegistry _pauserRegistry) external initializer {
        __Pausable_init();
        pauserRegistry = _pauserRegistry;
    }








}