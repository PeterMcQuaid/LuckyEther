// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {PauserRegistry} from "../../src/contracts/permissions/PauserRegistry.sol";
import {DeployPauserRegistry, UpdatePauserRegistryOwnerScript} from "../../script/DeployPauserRegistry.s.sol";

contract PauserRegistryTest is Test {
    DeployPauserRegistry deployPauserRegistry;
    PauserRegistry pauserRegistry;
    UpdatePauserRegistryOwnerScript updatePauserRegistryOwnerScript;

    address internal NEW_OWNER = makeAddr("newOwner");
    address internal PAUSER_ONE = makeAddr("pauserOne");
    address internal PAUSER_TWO = makeAddr("pauserTwo");
    address internal UNPAUSER_ONE = makeAddr("unpauserOne");
    address internal UNPAUSER_TWO = makeAddr("unpauserTwo");

    event PauserStatusChanged(address indexed pauser, bool canPause);
    event UnpauserStatusChanged(address indexed unpauser, bool canUnpause);
    event RegistryOwnerChanged(address previousRegistryOwner, address newRegistryOwner);

    function setUp() external {
        deployPauserRegistry = new DeployPauserRegistry();
        pauserRegistry = deployPauserRegistry.run();
    }

    function test_InitialOwner() external {
        assertEq(pauserRegistry.registryOwner(), msg.sender);
    }

    function test_InitialPausers() external {
        assertEq(pauserRegistry.isPauser(PAUSER_ONE), true);
        assertEq(pauserRegistry.isPauser(PAUSER_TWO), true);
    }

    function test_InitialUnpausers() external {
        assertEq(pauserRegistry.isUnpauser(UNPAUSER_ONE), true);
        assertEq(pauserRegistry.isUnpauser(UNPAUSER_TWO), true);
    }

    function testFuzz_UpdatePauserNotOwnerRevert(address notOwner) external {
        vm.assume(notOwner != pauserRegistry.registryOwner());
        bool currentStatus = pauserRegistry.isPauser(PAUSER_ONE);
        vm.expectRevert("Invalid sender, not the current owner");
        vm.prank(notOwner);
        pauserRegistry.updatePauser(PAUSER_ONE, !currentStatus);
    }

    function testFuzz_UpdateUnpauserNotOwnerRevert(address notOwner) external {
        vm.assume(notOwner != pauserRegistry.registryOwner());
        bool currentStatus = pauserRegistry.isUnpauser(UNPAUSER_ONE);
        vm.expectRevert("Invalid sender, not the current owner");
        vm.prank(notOwner);
        pauserRegistry.updateUnpauser(UNPAUSER_ONE, !currentStatus);
    }

    function test_UpdatePauserEmit() external {
        bool currentStatus = pauserRegistry.isPauser(PAUSER_ONE);
        vm.expectEmit(true, false, false, true, address(pauserRegistry));
        emit PauserStatusChanged(PAUSER_ONE, !currentStatus);
        vm.prank(pauserRegistry.registryOwner());
        pauserRegistry.updatePauser(PAUSER_ONE, !currentStatus);
    }

    function test_UpdateUnpauserEmit() external {
        bool currentStatus = pauserRegistry.isUnpauser(UNPAUSER_ONE);
        vm.expectEmit(true, false, false, true, address(pauserRegistry));
        emit UnpauserStatusChanged(UNPAUSER_ONE, !currentStatus);
        vm.prank(pauserRegistry.registryOwner());
        pauserRegistry.updateUnpauser(UNPAUSER_ONE, !currentStatus);
    }

    function test_UpdatePauserChanged() external {
        bool currentStatus = pauserRegistry.isPauser(PAUSER_ONE);
        vm.prank(pauserRegistry.registryOwner());
        pauserRegistry.updatePauser(PAUSER_ONE, !currentStatus);
        assertEq(pauserRegistry.isPauser(PAUSER_ONE), !currentStatus);
    }

    function test_UpdateUnpauserChanged() external {
        bool currentStatus = pauserRegistry.isUnpauser(UNPAUSER_ONE);
        vm.prank(pauserRegistry.registryOwner());
        pauserRegistry.updateUnpauser(UNPAUSER_ONE, !currentStatus);
        assertEq(pauserRegistry.isUnpauser(UNPAUSER_ONE), !currentStatus);
    }

    function testFuzz_UpdateRegistryOwnerNotOwnerRevert(address notOwner) external {
        vm.assume(notOwner != pauserRegistry.registryOwner());
        vm.expectRevert("Invalid sender, not the current owner");
        vm.prank(notOwner);
        pauserRegistry.updateRegistryOwner(NEW_OWNER);
    }

    function test_UpdateRegistryOwnerEmit() external {
        address currentOwner = pauserRegistry.registryOwner();
        vm.expectEmit(false, false, false, true, address(pauserRegistry));
        emit RegistryOwnerChanged(currentOwner, NEW_OWNER);
        vm.prank(pauserRegistry.registryOwner());
        pauserRegistry.updateRegistryOwner(NEW_OWNER);
    }

    function test_UpdateRegistryOwnerChanged() external {
        vm.prank(pauserRegistry.registryOwner());
        pauserRegistry.updateRegistryOwner(NEW_OWNER);
        assertEq(pauserRegistry.registryOwner(), NEW_OWNER);
    }
}