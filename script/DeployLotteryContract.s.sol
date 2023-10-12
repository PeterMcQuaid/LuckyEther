// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {LotteryContract} from "../src/contracts/core/LotteryContract.sol";
import {EmptyContract} from "../src/test/mocks/EmptyContract.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

contract ProxyAdminDeployScript is Script {
    function run() external returns (ProxyAdmin proxyAdmin) {
        
    }
}


contract EmptyContractDeployScript is Script {
    function run() external returns (EmptyContract emptyContract) {
        
    }
}


contract TransparentUpgradeableProxyDeployScript is Script {
    function run() external returns (TransparentUpgradeableProxy transparentUpgradeableProxy) {
        
    }
}


contract LotteryDeployScript is Script {
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

        vm.startBroadcast();
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
    function run() external {
        
    }
}


contract UpdateProxyAdminOwnerScript is Script {
    function run() external {
        
    }
}