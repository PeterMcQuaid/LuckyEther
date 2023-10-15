// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy, 
    ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {LotteryContract} from "../../src/contracts/core/LotteryContract.sol";
import {EmptyContract} from "../../src/test/mocks/EmptyContract.sol";
import {PauserRegistry} from "../../src/contracts/permissions/PauserRegistry.sol";
import {IPauserRegistry} from "../../src/contracts/interfaces/IPauserRegistry.sol";
import {EmptyContractDeployScript, 
    TransparentUpgradeableProxyDeployScript, 
    LotteryDeployScript, 
    InitializeImplementationScript, 
    UpdateProxyAdminOwnerScript} from "../../script/DeployLotteryContract.s.sol";
import {DeployPauserRegistry, UpdatePauserRegistryOwnerScript} from "../../script/DeployPauserRegistry.s.sol";

contract DeployScripts is Test {
    ProxyAdmin proxyAdmin;
    TransparentUpgradeableProxy transparentUpgradeableProxy;
    EmptyContract emptyContract;
    PauserRegistry pauserRegistry;
    LotteryContract lotteryContract;

    address internal DEPLOYER_ADDRESS = vm.envAddress("DEPLOYER_ADDRESS");
    address internal NEW_OWNER = makeAddr("newOwner");
    address internal PAUSER_ONE = makeAddr("pauserOne");
    address internal PAUSER_TWO = makeAddr("pauserTwo");
    address internal UNPAUSER_ONE = makeAddr("unpauserOne");
    address internal UNPAUSER_TWO = makeAddr("unpauserTwo");
    address[] internal initialPausers = [PAUSER_ONE, PAUSER_TWO];
    address[] internal initialUnpausers = [UNPAUSER_ONE, UNPAUSER_TWO];

    function setUp() external {
    }

    function test_EmptyContractDeployScript() external {
        EmptyContractDeployScript emptyContractDeployer = new EmptyContractDeployScript();
        emptyContract = emptyContractDeployer.run();
        assertEq(emptyContract.emptyFunction(), 0);
    }

    function test_TransparentUpgradeableProxyDeployScript() external {
        EmptyContractDeployScript emptyContractDeployer = new EmptyContractDeployScript();
        emptyContract = emptyContractDeployer.run();
        TransparentUpgradeableProxyDeployScript transparentUpgradeableProxyDeployer = new TransparentUpgradeableProxyDeployScript();
        (transparentUpgradeableProxy, proxyAdmin) = transparentUpgradeableProxyDeployer.run(emptyContract);
        assertEq(proxyAdmin.owner(), DEPLOYER_ADDRESS);
    }

    function test_LotteryDeployScript() external {
        LotteryDeployScript lotteryDeployScript = new LotteryDeployScript();
        (lotteryContract, ) = lotteryDeployScript.run();
        assertEq(lotteryContract.owner(), address(0));  // owner is not set until InitializeImplementationScript is run
    }

    function test_DeployPauserRegistry() external {
        DeployPauserRegistry pauserRegistryDeployer = new DeployPauserRegistry();
        pauserRegistry = pauserRegistryDeployer.run(initialPausers, initialUnpausers);
        assertEq(pauserRegistry.registryOwner(), DEPLOYER_ADDRESS);
    }

    function test_PauserRegistryScriptOwnerUpdated() external {
        DeployPauserRegistry pauserRegistryDeployer = new DeployPauserRegistry();
        pauserRegistry = pauserRegistryDeployer.run(initialPausers, initialUnpausers);
        UpdatePauserRegistryOwnerScript updatePauserRegistryOwnerScript = new UpdatePauserRegistryOwnerScript();
        updatePauserRegistryOwnerScript.run(address(pauserRegistry), NEW_OWNER);
        assertEq(pauserRegistry.registryOwner(), NEW_OWNER);
    }  
}