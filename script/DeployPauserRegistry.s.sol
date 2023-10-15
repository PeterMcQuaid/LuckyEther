// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {PauserRegistry} from "../src/contracts/permissions/PauserRegistry.sol";
import {IPauserRegistry} from "../src/contracts/interfaces/IPauserRegistry.sol";

contract DeployPauserRegistry is Script {
    address internal DEPLOYER_ADDRESS = vm.envAddress("DEPLOYER_ADDRESS");

    address internal NEW_OWNER = makeAddr("newOwner");
    address internal PAUSER_ONE = makeAddr("pauserOne");
    address internal PAUSER_TWO = makeAddr("pauserTwo");
    address internal UNPAUSER_ONE = makeAddr("unpauserOne");
    address internal UNPAUSER_TWO = makeAddr("unpauserTwo");

    address[] internal initialPausers = [PAUSER_ONE, PAUSER_TWO];
    address[] internal initialUnpausers = [UNPAUSER_ONE, UNPAUSER_TWO];

    function run() external returns(PauserRegistry) {
        vm.broadcast(DEPLOYER_ADDRESS);
        PauserRegistry pauserRegistry = new PauserRegistry(initialPausers, initialUnpausers);
        return pauserRegistry;
    }
}

contract UpdatePauserRegistryOwnerScript is Script {
    address internal DEPLOYER_ADDRESS = vm.envAddress("DEPLOYER_ADDRESS");

    address internal NEW_OWNER = makeAddr("newOwner");
    address internal PAUSER_ONE = makeAddr("pauserOne");
    address internal PAUSER_TWO = makeAddr("pauserTwo");
    address internal UNPAUSER_ONE = makeAddr("unpauserOne");
    address internal UNPAUSER_TWO = makeAddr("unpauserTwo");

    address[] internal initialPausers = [PAUSER_ONE, PAUSER_TWO];
    address[] internal initialUnpausers = [UNPAUSER_ONE, UNPAUSER_TWO];


    function run(IPauserRegistry pauserRegistry) external {
        vm.startBroadcast(DEPLOYER_ADDRESS);
        pauserRegistry.updateRegistryOwner(NEW_OWNER);
        vm.stopBroadcast();
    }
}