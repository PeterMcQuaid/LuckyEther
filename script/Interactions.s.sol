// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";


contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() internal returns (uint64) {
        HelperConfig helperConfig = new HelperConfig();
        (, , , , address chainlinkVrfCoordinator, , , , ) = helperConfig.activeNetworkConfig();
        return createSubscription(chainlinkVrfCoordinator);
    }

    function createSubscription(address vrfCoordinator) public returns (uint64 subId) {
        vm.startBroadcast();
        subId = VRFCoordinatorV2Mock(vrfCoordinator).createSubscription();
        console.log("Subscription created with id: %s on chain: %s", subId, block.chainid);
        vm.stopBroadcast();
    }

    function run() external returns (uint64) {
        return createSubscriptionUsingConfig();
    }
}


contract FundSubscription is Script {
    uint96 public constant FUND_AMOUNT = 1e18;  // 1 LINK

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        (, , , , address chainlinkVrfCoordinator, , uint64 subId, , address link) = helperConfig.activeNetworkConfig();
        fundSubscription(chainlinkVrfCoordinator, subId, link);
    }

    function fundSubscription(address vrfCoordinator, uint64 subId, address link) public {
        console.log("Funding subscription with: %s LINK", (FUND_AMOUNT)/1e18);
        if (block.chainid == 31337) {
            vm.startBroadcast();
            VRFCoordinatorV2Mock(vrfCoordinator).fundSubscription(subId, FUND_AMOUNT);  // Mock used as interface
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            LinkToken(link).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subId));
            vm.stopBroadcast();
        }
    }

    // Only required if we run this script directly from command line 
    function run() external {
        fundSubscriptionUsingConfig();
    }
}


contract AddConsumer is Script {
    function addConsumerUsingConfig(address lottery) public {
        HelperConfig helperConfig = new HelperConfig();
        (, , , , address chainlinkVrfCoordinator, , uint64 subId, , ) = helperConfig.activeNetworkConfig();
        addConsumer(lottery, chainlinkVrfCoordinator, subId);
    }

    function addConsumer(address lottery, address vrfCoordinator, uint64 subId) public {
        console.log("Adding consumer LotteryContract: %s", lottery);
        vm.startBroadcast();
        VRFCoordinatorV2Mock(vrfCoordinator).addConsumer(subId, lottery);    // Mock used as interface
        vm.stopBroadcast();
    }

    // Only required if we run this script directly from command line
    function run() external {
        address lottery = DevOpsTools.get_most_recent_deployment("LotteryContract", block.chainid);
        addConsumerUsingConfig(lottery);
    }
}