// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {PauserRegistry} from "../src/contracts/permissions/PauserRegistry.sol";

contract DeployPauserRegistry is Script {
    address internal NEW_OWNER = makeAddr("newOwner");
    address internal PAUSER_ONE = makeAddr("pauserOne");
    address internal PAUSER_TWO = makeAddr("pauserTwo");
    address internal UNPAUSER_ONE = makeAddr("unpauserOne");
    address internal UNPAUSER_TWO = makeAddr("unpauserTwo");

    address[] internal initialPausers = [PAUSER_ONE, PAUSER_TWO];
    address[] internal initialUnpausers = [UNPAUSER_ONE, UNPAUSER_TWO];

    function run() external returns(PauserRegistry) {
        vm.broadcast();
        PauserRegistry pauserRegistry = new PauserRegistry(initialPausers, initialUnpausers);
        return pauserRegistry;
    }
}

contract UpdatePauserRegistryOwnerScript is Script {
    address internal NEW_OWNER = makeAddr("newOwner");
    address internal PAUSER_ONE = makeAddr("pauserOne");
    address internal PAUSER_TWO = makeAddr("pauserTwo");
    address internal UNPAUSER_ONE = makeAddr("unpauserOne");
    address internal UNPAUSER_TWO = makeAddr("unpauserTwo");

    address[] internal initialPausers = [PAUSER_ONE, PAUSER_TWO];
    address[] internal initialUnpausers = [UNPAUSER_ONE, UNPAUSER_TWO];


    function run() external {
        vm.broadcast();
        PauserRegistry pauserRegistry = new PauserRegistry(initialPausers, initialUnpausers);
    }
}