// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {LotteryContract} from "../../src/contracts/core/LotteryContract.sol";
import {LotteryDeployScript} from "../../script/DeployLotteryContract.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract LotteryReentrancy is Test {
    LotteryContract lotteryContract;
    HelperConfig helperConfig;
    ReentrantPlayer reentrantPlayer;

    uint80 internal STARTING_USER_BALANCE = 1000000 ether;  // uint80 to narrow range when fuzzing

    uint256 internal lotteryDeposit;
    uint256 internal lotteryDuration;
    uint256 internal prizeExpiry;
    uint256 internal expiryGap;
    address internal vrfCoordinator;

    function setUp() external {
        LotteryDeployScript deployer = new LotteryDeployScript();
        (lotteryContract, helperConfig) = deployer.run();
        (lotteryDeposit, lotteryDuration, prizeExpiry, expiryGap, vrfCoordinator, , , , ) = helperConfig.activeNetworkConfig();
        reentrantPlayer = new ReentrantPlayer(lotteryContract);
    }

    // Random number chosen
    function randomWordChosen() internal pure returns (uint256[] memory randomWords, uint256 requestId) {
        requestId = 1;
        randomWords = new uint256[](1);
        randomWords[0] = uint256(keccak256("randomWord"));
    }

    function test_WinnerWithdrawalsReentrancyReverts() external {
        vm.deal(address(reentrantPlayer), STARTING_USER_BALANCE);
        reentrantPlayer.enterLottery{value: lotteryDeposit}();
        skip(lotteryDuration);
        lotteryContract.performUpkeep("");
        (uint256[] memory randomWords, uint256 requestId) = randomWordChosen();
        vm.prank(vrfCoordinator);
        lotteryContract.rawFulfillRandomWords(requestId, randomWords);
        reentrantPlayer.triggerReentrancyWithdrawalAttack();
    }
}


contract ReentrantPlayer is Test {
    LotteryContract lotteryContract;

    error ReentrancyGuardReentrantCall();

    constructor(LotteryContract _lotteryContract) {
        lotteryContract = _lotteryContract;
    }

    function enterLottery() external payable {
        lotteryContract.enterLottery{value: msg.value}();
    }

    function triggerReentrancyWithdrawalAttack() external {
        lotteryContract.winnerWithdraw();
    }

    receive() external payable {
        // Cheatcode needs to be used here since it is next call that we expect to REVERT
        vm.expectRevert(ReentrancyGuardReentrantCall.selector); 
        lotteryContract.winnerWithdraw();
    }
}