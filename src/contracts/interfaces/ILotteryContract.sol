// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;


/**
 * @title Interface for LotteryContract
 * @author Peter Raymond McQuaid
 */
interface ILotteryContract {
    event Initialized(uint64 version);
    event LotteryDeposit(address indexed user, uint256 deposit);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Paused(address account);
    event TreasuryFeeWithdrawal(address indexed owner, uint256 amount);
    event Unpaused(address account);
    event WinnerSuccessfulWithdraw(address indexed winner, uint256 prize);

    function checkUpkeep(bytes memory) external view returns (bool upkeepNeeded, bytes memory);
    function enterLottery() external payable;
    function getCurrentPrizePot() external view returns (uint256);
    function getCurrentWinner() external view returns (address);
    function getLastBlockTimestamp() external view returns (uint256);
    function getLotteryDeposit() external view returns (uint256);
    function getLotteryUsersLength() external view returns (uint256);
    function getLotteryWinnings() external view returns (uint256);
    function getPrizeExpiry() external view returns (uint256);
    function getlotteryDuration() external view returns (uint256);
    function initialize(address _pauserRegistry) external;
    function lotteryUsersContains(address user) external view returns (bool);
    function owner() external view returns (address);
    function pauseContract() external;
    function paused() external view returns (bool);
    function performUpkeep(bytes memory) external returns (uint256 requestId);
    function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external;
    function renounceOwnership() external;
    function transferOwnership(address newOwner) external;
    function unpauseContract() external;
    function winnerWithdraw() external;
    function withdraw(uint256 withdrawalAmount) external;
}

