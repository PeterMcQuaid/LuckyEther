// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LotteryContract} from "../../src/contracts/core/LotteryContract.sol";
import {LotteryDeployScript} from "../../script/DeployLotteryContract.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract LotteryPausable is Test {  
    LotteryContract lotteryContract;
    HelperConfig helperConfig;

    address internal PLAYER_1 = makeAddr("player1");
    uint256 internal STARTING_USER_BALANCE = 10 ether;

    // Namespaced storage slot for PausableUpgradeable contract
    bytes32 constant internal PAUSABLE_STORAGE_LOCATION = 0xcd5ed15c6e187e77e9aee88184c21f4f2182ab5827cb3b7e07fbedcd63f03300;
    bytes32 constant internal OWNABLE_STORAGE_LOCATION = 0x9016d09d72d40fdae2fd8ceac6b6234c7706214fd39c1cd1e609a0528c199300;

    uint256 internal lotteryDeposit;
    uint256 internal lotteryDuration;
    uint256 internal prizeExpiry;
    uint256 internal expiryGap;
    address internal vrfCoordinator;

    event WinnerSuccessfulWithdraw(address indexed winner, uint256 prize);

    error EnforcedPause();

    modifier skipFork() {
        if (block.chainid == 31337) {
            _;
        } else {
            return;
        }
    }

    modifier skipGoerliArbitrum() {
        if (block.chainid == 421613) {
            return;
        } else {
            _;
        }
    }

    function setUp() external {
        LotteryDeployScript deployer = new LotteryDeployScript();
        (lotteryContract, helperConfig) = deployer.run();
        (lotteryDeposit, lotteryDuration, prizeExpiry, expiryGap, vrfCoordinator, , , , ) = helperConfig.activeNetworkConfig();
        vm.deal(PLAYER_1, STARTING_USER_BALANCE);
    }

    // Sets up mock Pauser Registry contract logic (manipulating namespaced pausable storage slot)
    function setPauser(bool paused) internal {
        if (paused) {
            vm.store(address(lotteryContract), PAUSABLE_STORAGE_LOCATION, bytes32(uint256(1))); // Paused
        } else {
            vm.store(address(lotteryContract), PAUSABLE_STORAGE_LOCATION, bytes32(uint256(0))); // Unpaused
        }
    }

    // Sets up mock Pauser Registry contract logic (manipulating namespaced pausable storage slot)
    function setOwner(address owner) internal {
        vm.store(address(lotteryContract), OWNABLE_STORAGE_LOCATION, bytes32(abi.encode(owner))); // Paused
    }

    // PLAYER_1 enters lottery
    function playerEntersLottery() internal {
        vm.prank(PLAYER_1);
        lotteryContract.enterLottery{value: lotteryDeposit}();
    }

    function test_Deposit() external {
        playerEntersLottery();
    }

    function test_DepositPausedReverts() external {
        setPauser(true);
        vm.expectRevert(EnforcedPause.selector);
        playerEntersLottery();
    }

    function test_PerformUpkeep() external skipGoerliArbitrum {
        playerEntersLottery();
        skip(lotteryDuration);
        lotteryContract.performUpkeep("");
    }

    function test_PerformUpkeepPausedReverts() external {
        playerEntersLottery();
        skip(lotteryDuration);
        setPauser(true);
        vm.expectRevert(EnforcedPause.selector);
        lotteryContract.performUpkeep("");
    }

    function test_FulfillRandomWords() external skipFork {
        playerEntersLottery();
        skip(lotteryDuration);
        uint256 requestId = lotteryContract.performUpkeep("");
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(requestId, address(lotteryContract));
    }

    function test_WinnerWithdraw() external skipFork {
        playerEntersLottery();
        skip(lotteryDuration);
        uint256 requestId = lotteryContract.performUpkeep("");
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(requestId, address(lotteryContract));
        address winner = lotteryContract.getCurrentWinner();
        vm.expectEmit(true, false, false, false, address(lotteryContract));
		emit WinnerSuccessfulWithdraw(winner, 5); 	//Only testing Topic 1, not data
        vm.prank(winner);
        lotteryContract.winnerWithdraw();
    }
 
    function test_WinnerWithdrawPausedRevert() external skipFork {
        playerEntersLottery();
        skip(lotteryDuration);
        uint256 requestId = lotteryContract.performUpkeep("");
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(requestId, address(lotteryContract));
        address winner = lotteryContract.getCurrentWinner();
        setPauser(true);
        vm.expectRevert(EnforcedPause.selector);
        vm.prank(winner);
        lotteryContract.winnerWithdraw();
    }

    function test_Withdraw() external {
        vm.deal(address(lotteryContract), STARTING_USER_BALANCE);
        setOwner(msg.sender);
        vm.prank(msg.sender);
        lotteryContract.withdraw(1 wei);
    }

    function test_WithdrawPausedRevert() external {
        vm.deal(address(lotteryContract), STARTING_USER_BALANCE);
        setOwner(msg.sender);
        setPauser(true);
        vm.expectRevert(EnforcedPause.selector);
        vm.prank(msg.sender);
        lotteryContract.withdraw(1 wei);
    }
}