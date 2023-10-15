// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {PauserRegistry} from "../src/contracts/permissions/PauserRegistry.sol";
import {IPauserRegistry} from "../src/contracts/interfaces/IPauserRegistry.sol";

contract DeployPauserRegistry is Script {
    address internal DEPLOYER_ADDRESS = vm.envAddress("DEPLOYER_ADDRESS");

    function run(address[] memory _initialPausers, address[] memory _initialUnpausers) external returns(PauserRegistry) {
        vm.startBroadcast(DEPLOYER_ADDRESS);
        PauserRegistry pauserRegistry = new PauserRegistry(_initialPausers, _initialUnpausers);
        vm.stopBroadcast();
        return pauserRegistry;
    }
}

contract UpdatePauserRegistryOwnerScript is Script {
    address internal DEPLOYER_ADDRESS = vm.envAddress("DEPLOYER_ADDRESS");

    function run(address _pauserRegistry, address _newOwner) external {
        vm.startBroadcast(DEPLOYER_ADDRESS);
        IPauserRegistry(_pauserRegistry).updateRegistryOwner(_newOwner);
        vm.stopBroadcast();
    }
}