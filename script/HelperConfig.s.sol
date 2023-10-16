// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        uint256 lotteryDeposit; 
        uint256 lotteryDuration; 
        uint256 prizeExpiry;
        uint256 expiryGap;
        address chainlinkVrfCoordinator; 
        bytes32 vrfKeyHash;
        uint64 vrfSubscriptionID;
        uint32 callbackGasLimit;
        address link;
    }

    NetworkConfig public activeNetworkConfig;

    // TEST CONSTANTS

    uint256 private constant LOTTERY_DEPOSIT_TESTNET = 0.01 ether;
    uint256 private constant LOTTERY_DURATION = 1 days;
    uint256 private constant PRIZE_EXPIRY = 12 hours;
    uint256 private constant EXPIRY_GAP = 10 hours;
    uint32 private constant CALLBACK_GAS_LIMIT = 500000;

    constructor() {
        if (block.chainid == 421613) {
            activeNetworkConfig = getArbitrumGoerliConfig();
        } else if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    // LOCAL ANVIL NETWORK

    /// @dev Need to deploy mock VRF coordinator if not on supported network local fork
    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.chainlinkVrfCoordinator != address(0)) {
            return activeNetworkConfig;
        } else {
            uint96 baseFee = 25e8; // 0.25 LINK
            uint96 gasPriceLink = 1e9; // 1 LINK

            vm.startBroadcast();
            VRFCoordinatorV2Mock vrfCoordinatorV2Mock = new VRFCoordinatorV2Mock(baseFee, gasPriceLink);
            LinkToken linkToken = new LinkToken();  
            vm.stopBroadcast();

            return NetworkConfig({
                lotteryDeposit: LOTTERY_DEPOSIT_TESTNET,
                lotteryDuration: LOTTERY_DURATION,
                prizeExpiry: PRIZE_EXPIRY,
                expiryGap: EXPIRY_GAP,
                chainlinkVrfCoordinator: address(vrfCoordinatorV2Mock),
                vrfKeyHash: 0x83d1b6e3388bed3d76426974512bb0d270e9542a765cd667242ea26c0cc0b730, // Unused here
                vrfSubscriptionID: 0,
                callbackGasLimit: CALLBACK_GAS_LIMIT,
                link: address(linkToken)
            });
        }
    }

    // TESTNETS

    function getArbitrumGoerliConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            lotteryDeposit: LOTTERY_DEPOSIT_TESTNET,
            lotteryDuration: LOTTERY_DURATION,
            prizeExpiry: PRIZE_EXPIRY,
            expiryGap: EXPIRY_GAP,
            chainlinkVrfCoordinator: 0x6D80646bEAdd07cE68cab36c27c626790bBcf17f,
            vrfKeyHash: 0x83d1b6e3388bed3d76426974512bb0d270e9542a765cd667242ea26c0cc0b730, // 50 Gwei key hash (max)
            vrfSubscriptionID: 142,
            callbackGasLimit: CALLBACK_GAS_LIMIT,
            link: 0xd14838A68E8AFBAdE5efb411d5871ea0011AFd28
        });
    }

    function getSepoliaConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            lotteryDeposit: LOTTERY_DEPOSIT_TESTNET,
            lotteryDuration: LOTTERY_DURATION,
            prizeExpiry: PRIZE_EXPIRY,
            expiryGap: EXPIRY_GAP,
            chainlinkVrfCoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
            vrfKeyHash: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c, // 30 Gwei key hash (max)
            vrfSubscriptionID: 5924,
            callbackGasLimit: CALLBACK_GAS_LIMIT,
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789
        });
    }
}