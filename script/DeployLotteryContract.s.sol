// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {Vm} from "forge-std/Vm.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy, ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {LotteryContract} from "../src/contracts/core/LotteryContract.sol";
import {EmptyContract} from "../src/test/mocks/EmptyContract.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";
import {IPauserRegistry} from "../src/contracts/interfaces/IPauserRegistry.sol";

contract EmptyContractDeployScript is Script {
    address internal DEPLOYER_ADDRESS = vm.envAddress("DEPLOYER_ADDRESS");

    function run() external returns (EmptyContract emptyContract) {
        vm.startBroadcast(DEPLOYER_ADDRESS);
        emptyContract = new EmptyContract();
        vm.stopBroadcast();
    }
}


contract TransparentUpgradeableProxyDeployScript is Script {
    address internal DEPLOYER_ADDRESS = vm.envAddress("DEPLOYER_ADDRESS");

    function run(EmptyContract _emptyContract) external returns (TransparentUpgradeableProxy transparentUpgradeableProxy, ProxyAdmin proxyAdmin) {
        vm.recordLogs();
        vm.startBroadcast(DEPLOYER_ADDRESS);
        transparentUpgradeableProxy = new TransparentUpgradeableProxy(
            address(_emptyContract),
            DEPLOYER_ADDRESS,
            ""
        );
        vm.stopBroadcast();
        Vm.Log[] memory entries = vm.getRecordedLogs();
        (, address newAdmin) = abi.decode(entries[2].data, (address, address));
        console.log("New admin is: %s", newAdmin);
        return (transparentUpgradeableProxy, ProxyAdmin(newAdmin));
    }
}


contract LotteryDeployScript is Script {
    address internal DEPLOYER_ADDRESS = vm.envAddress("DEPLOYER_ADDRESS");

    function run() external returns (LotteryContract lotteryContract, HelperConfig helperConfig) {
        helperConfig = new HelperConfig();
        (
            uint256 lotteryDeposit, 
            uint256 lotteryDuration, 
            uint256 prizeExpiry,
            uint256 expiryGap,
            address chainlinkVrfCoordinator,
            bytes32 vrfKeyHash,
            uint64 vrfSubscriptionID,
            uint32 callbackGasLimit,
            address link
        ) = helperConfig.activeNetworkConfig();

        if (vrfSubscriptionID == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            vrfSubscriptionID = createSubscription.createSubscription(chainlinkVrfCoordinator);

            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(chainlinkVrfCoordinator, vrfSubscriptionID, link);
        }

        vm.startBroadcast(DEPLOYER_ADDRESS);
        lotteryContract = new LotteryContract(
            lotteryDeposit, 
            lotteryDuration, 
            prizeExpiry,
            expiryGap,
            chainlinkVrfCoordinator,
            vrfKeyHash,
            vrfSubscriptionID,
            callbackGasLimit
        );
        vm.stopBroadcast();

        // Don't need to wrap in broadcast here because "addConsumer()" in Interactions.s.sol does it already
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(address(lotteryContract), chainlinkVrfCoordinator, vrfSubscriptionID);
    }
}


contract InitializeImplementationScript is Script {
    address internal DEPLOYER_ADDRESS = vm.envAddress("DEPLOYER_ADDRESS");

    function run(
        ProxyAdmin _proxyAdmin, 
        ITransparentUpgradeableProxy _transparentUpgradeableProxy,
        address _lotteryContract,
        IPauserRegistry _pauserRegistry
        ) external 
        {
            vm.startBroadcast(DEPLOYER_ADDRESS);
            _proxyAdmin.upgradeAndCall(
                _transparentUpgradeableProxy,
                _lotteryContract,
                abi.encodeWithSignature("initialize(address)", _pauserRegistry) // Just empty bytes "" if already initialized
            );
            vm.stopBroadcast();
        }
}


// Update owner from deployer EOA to community multisig
contract UpdateProxyAdminOwnerScript is Script {
    address internal DEPLOYER_ADDRESS = vm.envAddress("DEPLOYER_ADDRESS");

    function run(ProxyAdmin _proxyAdmin, address communityMultisig) external {
        vm.startBroadcast(DEPLOYER_ADDRESS);
        _proxyAdmin.transferOwnership(communityMultisig);
        vm.stopBroadcast();
    }
}