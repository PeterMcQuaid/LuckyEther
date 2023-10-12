// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {LotteryContract} from "../../src/contracts/core/LotteryContract.sol";
import {LotteryDeployScript} from "../../script/DeployLotteryContract.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {IPauserRegistry} from "../../src/contracts/interfaces/IPauserRegistry.sol";

contract LotteryMainLogic is Test {
    LotteryContract lotteryContract;
    HelperConfig helperConfig;

    address internal PLAYER_1 = makeAddr("player1");
    IPauserRegistry internal PAUSER_REGISTRY_MOCK = IPauserRegistry(makeAddr("pauserRegistryMock"));
    uint80 internal STARTING_USER_BALANCE = 1000000 ether;  // uint80 to narrow range when fuzzing

    // Namespaced storage slot for PausableUpgradeable contract
    bytes32 constant internal PAUSABLE_STORAGE_LOCATION = 0xcd5ed15c6e187e77e9aee88184c21f4f2182ab5827cb3b7e07fbedcd63f03300;
    bytes32 constant internal OWNABLE_STORAGE_LOCATION = 0x9016d09d72d40fdae2fd8ceac6b6234c7706214fd39c1cd1e609a0528c199300;

    uint256 internal lotteryDeposit;
    uint256 internal lotteryDuration;
    uint256 internal prizeExpiry;
    uint256 internal expiryGap;
    address internal vrfCoordinator;

    event LotteryDeposit(address indexed user, uint256 deposit);
    event TreasuryFeeWithdrawal(address indexed owner, uint256 amount);
    event WinnerSuccessfulWithdraw(address indexed winner, uint256 prize);

    error InvalidInitialization();
    error OwnableUnauthorizedAccount(address account);
    error UpkeepNotRequired();
    error WinnerFailedWithdrawl();

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
    function playerEntersLottery(uint256 _lotteryDeposit) internal {
        vm.prank(PLAYER_1);
        lotteryContract.enterLottery{value: _lotteryDeposit}();
    }

    // Random number chosen
    function randomWordChosen() internal pure returns (uint256[] memory randomWords, uint256 requestId) {
        requestId = 1;
        randomWords = new uint256[](1);
        randomWords[0] = uint256(keccak256("randomWord"));
    }

    // PLAYER_1 is only entrant and winner of current round
    function playerWinsRound() internal {
        playerEntersLottery(lotteryDeposit);
        skip(lotteryDuration);
        lotteryContract.performUpkeep("");
        (uint256[] memory randomWords, uint256 requestId) = randomWordChosen();
        vm.prank(vrfCoordinator);
        lotteryContract.rawFulfillRandomWords(requestId, randomWords);
    }

    function potAfterProtocolFees(uint256 grossPot) internal pure returns (uint256 netPot) {
        netPot = (grossPot * 995) / 1000;
    }

    /*
     INVARIANTS - Not meaningful enough, even with Handlers, due to strict sequence of events and randomness
     present. Would cause too many unneccessary REVERTs
    */

    /*
    function invariant_PrizePot() external {
        assertLe(lotteryContract.getCurrentPrizePot(), address(lotteryContract).balance);
    }
    */

    // INITIALIZE

    function test_InitializeCallReverts() external {
        vm.expectRevert(InvalidInitialization.selector);
        vm.prank(PLAYER_1);
        lotteryContract.initialize(PAUSER_REGISTRY_MOCK);
    }

    // ENTER LOTTERY

    function testFuzz_IncorrectDepositReverts(uint256 incorrectDeposit) external {
        vm.assume(incorrectDeposit != lotteryDeposit);
        incorrectDeposit = bound(incorrectDeposit, 0, STARTING_USER_BALANCE);
        vm.expectRevert("LotteryContract.enterLottery: Incorrect amount deposited");
        playerEntersLottery(incorrectDeposit);
    }

    function test_DoubleDepositReverts() external {
        playerEntersLottery(lotteryDeposit);
        vm.expectRevert("LotteryContract.enterLottery: Not allow more than 1 deposit in given session");
        playerEntersLottery(lotteryDeposit);
    }

    function test_ExpiredTimeReverts() external {
        skip(lotteryDuration);
        vm.expectRevert("Invalid call, your time period has expired");
        playerEntersLottery(lotteryDeposit);
    }

    function test_EnterLotteryCurrentPrizePot() external {
        uint256 currentPrizePotBefore = lotteryContract.getCurrentPrizePot();
        playerEntersLottery(lotteryDeposit);
        uint256 currentPrizePotAfter = lotteryContract.getCurrentPrizePot();
        assertEq(currentPrizePotAfter, currentPrizePotBefore + lotteryDeposit);
    }

    function test_EnterLotteryCurrentPrizeAndLotteryBalance() external {
        uint256 currentPrizePotBefore = lotteryContract.getCurrentPrizePot();
        uint256 LotteryBalanceBefore = address(lotteryContract).balance;
        playerEntersLottery(lotteryDeposit);
        uint256 currentPrizePotAfter = lotteryContract.getCurrentPrizePot();
        uint256 LotteryBalanceAfter = address(lotteryContract).balance;
        assertEq(LotteryBalanceAfter - LotteryBalanceBefore, currentPrizePotAfter - currentPrizePotBefore);
    }

    function test_EnterLotteryEmitDeposit() external {
        vm.expectEmit(true, false, false, true, address(lotteryContract));
        emit LotteryDeposit(PLAYER_1, lotteryDeposit);
        playerEntersLottery(lotteryDeposit);
    }

    function test_EnterLotteryUserAdded() external {
        playerEntersLottery(lotteryDeposit);
        assertEq(lotteryContract.getLotteryUsersLength(), 1);
        assertEq(lotteryContract.lotteryUsersContains(PLAYER_1), true);
    }

    // PERFORM UPKEEP

    function test_UpkeepNotNeededReverts() external {
        playerEntersLottery(lotteryDeposit);
        skip(lotteryDuration - 1);
        vm.expectRevert(UpkeepNotRequired.selector);
        lotteryContract.performUpkeep("");
    }

    function test_NoPlayersReverts() external {
        skip(lotteryDuration);
        vm.expectRevert(UpkeepNotRequired.selector);
        lotteryContract.performUpkeep("");
    }

    function test_UpkeepNeeded() external {
        playerEntersLottery(lotteryDeposit);
        skip(lotteryDuration);
        lotteryContract.performUpkeep("");
    }

    function test_CorrectWinnerSelectedAndReset() external {
        playerWinsRound();
        assertEq(lotteryContract.getCurrentWinner(), PLAYER_1);
        playerEntersLottery(lotteryDeposit);
        skip(lotteryDuration);
        lotteryContract.performUpkeep("");
        assertEq(lotteryContract.getCurrentWinner(), address(0));
    }

    // WINNER SELECTION AND WITHDRAWAL

    function test_WinnerWithdrawExpiredReverts() external {
        playerWinsRound();
        skip(prizeExpiry);
        vm.expectRevert("Invalid call, your time period has expired");
        vm.prank(PLAYER_1);
        lotteryContract.winnerWithdraw();
    }

    function testFuzz_NotWinnerReverts(address invalidClaimer) external {
        vm.assume(invalidClaimer != PLAYER_1);
        playerWinsRound();
        vm.expectRevert("Invalid winner, you are not the current winner");
        vm.prank(invalidClaimer);
        lotteryContract.winnerWithdraw();
    }

    function test_WinnerWithdrawSuccessEmits() external {
        playerWinsRound();
        vm.prank(PLAYER_1);
        vm.expectEmit(true, false, false, false, address(lotteryContract));
        emit WinnerSuccessfulWithdraw(PLAYER_1, lotteryDeposit); // Only testing Topic 1, not data
        lotteryContract.winnerWithdraw();
    }

    function test_SnapshotAndOngoingPotBalances() external {
        playerWinsRound();
        assertEq(lotteryContract.getCurrentPrizePot(), lotteryContract.getLotteryWinnings());
    }

    function test_SnapshotResets() external {
        playerWinsRound();
        vm.prank(PLAYER_1);
        lotteryContract.winnerWithdraw();
        assertEq(lotteryContract.getLotteryWinnings(), 0);
    }

    function test_CurrentPotDecrements() external {
        playerWinsRound();
        uint256 previousPot = lotteryContract.getCurrentPrizePot();
        uint256 currentLotteryWinnings = lotteryContract.getLotteryWinnings();
        vm.prank(PLAYER_1);
        lotteryContract.winnerWithdraw();
        assertEq(previousPot - lotteryContract.getCurrentPrizePot(), currentLotteryWinnings);
    }

    function test_ProtocolFeeCorrectlySubtracts() external {
        playerWinsRound();
        uint256 potAfterFees = potAfterProtocolFees(lotteryDeposit); 
        assertEq(lotteryContract.getCurrentPrizePot(), potAfterFees);
    }

    function test_BlockTimeStampUpdates() external {
        uint256 timeBefore = block.timestamp;
        playerWinsRound();
        assertEq(lotteryContract.getLastBlockTimestamp(), block.timestamp);
        assertEq(lotteryContract.getLastBlockTimestamp() - timeBefore, lotteryDuration);
    }

    function test_PlayerListClearsAfterRound() external {
        playerEntersLottery(lotteryDeposit);
        skip(lotteryDuration);
        assertEq(lotteryContract.getLotteryUsersLength(), 1);
        lotteryContract.performUpkeep("");
        (uint256[] memory randomWords, uint256 requestId) = randomWordChosen();
        vm.prank(vrfCoordinator);
        lotteryContract.rawFulfillRandomWords(requestId, randomWords);
        assertEq(lotteryContract.getLotteryUsersLength(), 0);
    }

    function test_PotRollsOver() external {
        playerWinsRound();
        uint256 timestampAfterFirstWin = block.timestamp;
        uint256 potAfterFees = potAfterProtocolFees(lotteryDeposit);
        assertEq(lotteryContract.getCurrentPrizePot(), potAfterFees);
        skip(prizeExpiry);  // Winner misses pot claim
        playerEntersLottery(lotteryDeposit);
        assertEq(lotteryContract.getCurrentPrizePot(), potAfterFees + lotteryDeposit);
        vm.warp(timestampAfterFirstWin + lotteryDuration);  // Warp to end of second round
        lotteryContract.performUpkeep("");
        (uint256[] memory randomWords, uint256 requestId) = randomWordChosen();
        vm.prank(vrfCoordinator);
        lotteryContract.rawFulfillRandomWords(requestId, randomWords);
        potAfterFees = potAfterProtocolFees(potAfterFees + lotteryDeposit);
        assertEq(lotteryContract.getCurrentPrizePot(), potAfterFees);
    }

    function test_WinnerWithdrawTransferReverts() external {
        lotteryContract.enterLottery{value: lotteryDeposit}();
        skip(lotteryDuration);
        lotteryContract.performUpkeep("");
        (uint256[] memory randomWords, uint256 requestId) = randomWordChosen();
        vm.prank(vrfCoordinator);
        lotteryContract.rawFulfillRandomWords(requestId, randomWords);
        vm.expectRevert(WinnerFailedWithdrawl.selector);
        lotteryContract.winnerWithdraw();
    }

    // OWNER WITHDRAW

    function testFuzz_WithdrawNotOwnerReverts(address notOwner) external {
        vm.deal(address(lotteryContract), lotteryDeposit);
        setOwner(msg.sender);
        vm.assume(notOwner != msg.sender);
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, notOwner));
        vm.prank(notOwner);
        lotteryContract.withdraw(lotteryDeposit - 1);
    }

    function test_WithdrawZeroReverts() external {
        vm.deal(address(lotteryContract), lotteryDeposit);
        setOwner(msg.sender);
        vm.expectRevert("LotteryContract.withdraw: Cannot withdraw 0 Ether");
        vm.prank(msg.sender);
        lotteryContract.withdraw(0);
    }

    function test_WithdrawMaxReverts() external {
        playerWinsRound();
        uint256 currentPrizePot = lotteryContract.getCurrentPrizePot();
        uint256 protocolFees = address(lotteryContract).balance - currentPrizePot;
        setOwner(msg.sender);
        vm.expectRevert("LotteryContract.withdraw: Insufficient protocol funds for withdrawal amount");
        vm.prank(msg.sender);
        lotteryContract.withdraw(protocolFees + 1);
    }

    function test_WithdrawOwnerTransferReverts() external {
        vm.deal(address(lotteryContract), lotteryDeposit);
        setOwner(address(this));
        vm.expectRevert("LotteryContract.withdraw: Error in transfer of withdrawal amount");
        lotteryContract.withdraw(lotteryDeposit);
    }

    function test_WithdrawSuccessEmit() external {
        vm.deal(address(lotteryContract), lotteryDeposit);
        setOwner(msg.sender);
        vm.expectEmit(true, false, false, true, address(lotteryContract));
        emit TreasuryFeeWithdrawal(msg.sender, lotteryDeposit);
        vm.prank(msg.sender);
        lotteryContract.withdraw(lotteryDeposit);
    }

    // VIEW FUNCTIONS

    function test_GetLotteryDeposit() external {
        assertEq(lotteryContract.getLotteryDeposit(), lotteryDeposit);
    }

    function test_GetlotteryDuration() external {
        assertEq(lotteryContract.getlotteryDuration(), lotteryDuration);
    }

    function test_GetPrizeExpiry() external {
        assertEq(lotteryContract.getPrizeExpiry(), prizeExpiry);
    }
}