// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy, 
    ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {LotteryContract} from "../../src/contracts/core/LotteryContract.sol";
import {ILotteryContract} from "../../src/contracts/interfaces/ILotteryContract.sol";
import {EmptyContract} from "../../src/test/mocks/EmptyContract.sol";
import {PauserRegistry} from "../../src/contracts/permissions/PauserRegistry.sol";
import {IPauserRegistry} from "../../src/contracts/interfaces/IPauserRegistry.sol";
import {EmptyContractDeployScript, 
    TransparentUpgradeableProxyDeployScript, 
    LotteryDeployScript, 
    InitializeImplementationScript, 
    UpdateProxyAdminOwnerScript} from "../../script/DeployLotteryContract.s.sol";
import {DeployPauserRegistry, UpdatePauserRegistryOwnerScript} from "../../script/DeployPauserRegistry.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract Integrations is Test {
    ProxyAdmin proxyAdmin;
    TransparentUpgradeableProxy transparentUpgradeableProxy;
    EmptyContract emptyContract;
    PauserRegistry pauserRegistry;
    LotteryContract lotteryContract;
    HelperConfig helperConfig;
    ILotteryContract myProxy;
    
    TransparentUpgradeableProxyDeployScript transparentUpgradeableProxyDeployer = new TransparentUpgradeableProxyDeployScript();
    EmptyContractDeployScript emptyContractDeployer = new EmptyContractDeployScript();
    DeployPauserRegistry pauserRegistryDeployer = new DeployPauserRegistry();
    UpdatePauserRegistryOwnerScript updatePauserRegistryOwnerScript = new UpdatePauserRegistryOwnerScript();
    LotteryDeployScript deployer = new LotteryDeployScript();
    InitializeImplementationScript initializeImplementationScript = new InitializeImplementationScript();

    address internal PLAYER_1 = makeAddr("player1");
    address internal COMMUNITY_MULTISIG_MOCK = makeAddr("communityMultisigMock");
    uint80 internal STARTING_USER_BALANCE = 1000000 ether;  // uint80 to narrow range when fuzzing
    address internal DEPLOYER_ADDRESS = vm.envAddress("DEPLOYER_ADDRESS");
    address internal NEW_OWNER = makeAddr("newOwner");
    address internal PAUSER_ONE = makeAddr("pauserOne");
    address internal PAUSER_TWO = makeAddr("pauserTwo");
    address internal UNPAUSER_ONE = makeAddr("unpauserOne");
    address internal UNPAUSER_TWO = makeAddr("unpauserTwo");

    uint256 internal lotteryDeposit;
    uint256 internal lotteryDuration;
    uint256 internal prizeExpiry;
    uint256 internal expiryGap;
    address internal vrfCoordinator;

    event LotteryDeposit(address indexed user, uint256 deposit);
    event Paused(address account);
    event Unpaused(address account);

    error EnforcedPause();
    error InvalidInitialization();

    function setUp() external {
        // Deploy EmptyContract
        emptyContract = emptyContractDeployer.run();

        // Deploy TransparentUpgradeableProxy
        /*
            NOTE: As of Openzeppelin v5.0.0 - "Admin is now stored in an immutable variable (set during construction) to avoid 
            unnecessary storage reads on every proxy call. This removed the ability to ever change the admin. Transfer of the 
            upgrade capability is exclusively handled through the ownership of the ProxyAdmin"

            Source: https://github.com/OpenZeppelin/openzeppelin-contracts/releases/tag/v5.0.0

            Therefore we don't deploy the ProxyAdmin separetly and pass in the admin as argument to TransparentUpgradeableProxy, but 
            rather deploying the TransparentUpgradeableProxy also deploys a new instance of ProxyAdmin, owned by "initialOwner" 
            argument passed into the TransparentUpgradeableProxy constructor.

            This was basically done to avoid the need to SLOAD every time the TransparentUpgradeableProxy is called, in order to 
            determine whether or not to call admin functions or DELEGATECALL to implementation. However although the admin is now
            an immutable, it's value is still stored in the ProxyAdmin slot defined in ERC-1967 at 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
            and is also emitted by the LOG "event AdminChanged(address previousAdmin, address newAdmin);"
        */
        (transparentUpgradeableProxy, proxyAdmin) = transparentUpgradeableProxyDeployer.run(emptyContract);

        // Deploy PauserRegistry
        pauserRegistry = pauserRegistryDeployer.run();

        // Deploy LotteryContract
        (lotteryContract, helperConfig) = deployer.run();
        (lotteryDeposit, lotteryDuration, prizeExpiry, expiryGap, vrfCoordinator, , , , ) = helperConfig.activeNetworkConfig();

        // Initialize LotteryContract
        initializeImplementationScript.run(
            proxyAdmin, 
            ITransparentUpgradeableProxy(address(transparentUpgradeableProxy)), 
            address(lotteryContract),
            IPauserRegistry(address(pauserRegistry))
        );        

        console.log("proxyAdmin: ", address(proxyAdmin));
        console.log("transparentUpgradeableProxy: ", address(transparentUpgradeableProxy));
        console.log("emptyContract: ", address(emptyContract));
        console.log("pauserRegistry: ", address(pauserRegistry));
        console.log("lotteryContract: ", address(lotteryContract));

        // Allowing interaction with implementation functions on TransparentUpgradeableProxy
        myProxy = ILotteryContract(address(transparentUpgradeableProxy));
        
        vm.deal(PLAYER_1, STARTING_USER_BALANCE);
    }

    function test_ProxyAdminOwnerUpdated() external {
        UpdateProxyAdminOwnerScript updateProxyAdminOwnerScript = new UpdateProxyAdminOwnerScript();
        updateProxyAdminOwnerScript.run(proxyAdmin, COMMUNITY_MULTISIG_MOCK);
        assert(proxyAdmin.owner() == COMMUNITY_MULTISIG_MOCK);
    }

    function test_RegistryOwner() external {
        assert(pauserRegistry.registryOwner() == DEPLOYER_ADDRESS);
    }

    function testFuzz_InitializeImplementationRevert(address attacker) external {
        vm.expectRevert(InvalidInitialization.selector);
        vm.prank(attacker);
        myProxy.initialize(address(pauserRegistry));
    }

    function test_EnterLotteryNotPaused() external {
        console.log(myProxy.getLastBlockTimestamp());
        console.log(block.timestamp);
        vm.expectEmit(true, false, false, true, address(myProxy));
        emit LotteryDeposit(PLAYER_1, lotteryDeposit);
        vm.prank(PLAYER_1);
        myProxy.enterLottery{value: lotteryDeposit}();
    }

    function test_Paused() external {
        assertEq(pauserRegistry.isPauser(PAUSER_ONE), true);
        vm.expectEmit(true, false, false, false, address(myProxy));
        emit Paused(PAUSER_ONE);
        vm.prank(PAUSER_ONE);
        myProxy.pauseContract();
    }

    function test_Unpaused() external {
        assertEq(pauserRegistry.isPauser(PAUSER_ONE), true);    // Need to pause before unpausing
        vm.prank(PAUSER_ONE);
        myProxy.pauseContract();
        assertEq(pauserRegistry.isUnpauser(UNPAUSER_ONE), true);
        vm.expectEmit(true, false, false, false, address(myProxy));
        emit Unpaused(UNPAUSER_ONE);
        vm.prank(UNPAUSER_ONE);
        myProxy.unpauseContract();
    }

    function test_EnterLotteryPausedReverts() external {
        assertEq(pauserRegistry.isPauser(PAUSER_ONE), true);
        vm.prank(PAUSER_ONE);
        myProxy.pauseContract();
        vm.expectRevert(EnforcedPause.selector);
        vm.prank(PLAYER_1);
        myProxy.enterLottery{value: lotteryDeposit}();
    }

    function test_EnterLotteryPausedUnpausedEmits() external {
        assertEq(pauserRegistry.isPauser(PAUSER_ONE), true);
        vm.prank(PAUSER_ONE);
        myProxy.pauseContract();
        assertEq(pauserRegistry.isUnpauser(UNPAUSER_ONE), true);
        vm.prank(UNPAUSER_ONE);
        myProxy.unpauseContract();
        vm.expectEmit(true, false, false, true, address(myProxy));
        emit LotteryDeposit(PLAYER_1, lotteryDeposit);
        vm.prank(PLAYER_1);
        myProxy.enterLottery{value: lotteryDeposit}();
    }
} 