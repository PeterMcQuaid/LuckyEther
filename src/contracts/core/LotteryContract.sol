// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IPauserRegistry} from "../interfaces/IPauserRegistry.sol";

/**
 * @title A lottery contract with automated prize payouts
 * @author Peter Raymond McQuaid
 * @notice The functionalities of this contract are:
 * - accepting Ether raffle deposits within each session
 * - 1 winner is randomly selected (Chainlink VRF) after each session duration has expired
 * - winner selection is triggered via Chainlink Automation
 * - a hard-coded protocol fee of 50bps is applied per deposit
 * - winner has limited time to claim their pot, otherwise their winnings will
 * roll over into the next prize pot
 * - protocol owner may withdraw fees during normal operation at any time
 * @dev This implementation contract is upgradable via the 
 * {TransparentUpgradeableProxy} proxy pattern, and pausable through a pauser registry
 * @dev The EnumerableSet AddressSet data type is used for tracking the lottery users to 
 * ensure the uniqueness of elements and to provide constant-time complexity (O(1)) for adding, removing 
 * and checking the existence of elements. In contrast, checking for existence in an array is O(n)
 * @dev Utilizes Chainlink VRF via the subscription mode
 */
contract LotteryContract is PausableUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable, VRFConsumerBaseV2 {
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     * @notice The lottery deposit users for the current session 
     * @dev Addresses are not stored as payable directly, only singly converted upon payout
     */
    EnumerableSet.AddressSet private lotteryUsers;

    /// @notice Current winner that can claim their prize pot
    address payable private currentWinner;

    /**
     * @notice Current (gross) prize pot for current winner to claim
     * @dev The pot can continue to roll-over indefinitely if left unclaimed
     */
    uint256 private currentPrizePot;

    /// @notice Snapshots the pot size at raffle time for payout to winner
    uint256 private lotteryWinnings;

    /// @notice The external "PauserRegistry" contract
    IPauserRegistry private pauserRegistry;

    /// @notice Timestamp of previous lottery end
    uint256 private lastBlockTimestamp;

    /// @notice Number of block confirmations for random number to be acceptable
    uint16 private constant REQUEST_CONFIRMATIONS = 3;

    /// @notice Number of random numbers we receive back
    uint32 private constant NUM_WORDS = 1;

    /// @notice Exact deposit to enter the lottery raffle in Wei
    uint256 private immutable lotteryDeposit;

    /// @notice Duration of each lottery in seconds
    uint256 private immutable lotteryDuration;

    /// @notice Duration for current winner to withdraw prize pot
    uint256 private immutable prizeExpiry;

    /**
     * @notice The number of days the lottery session "lotteryDuration" must be greater 
     * than the prize expiry duration "prizeExpiry"
     */
    uint256 private immutable expiryGap;

    /// @notice Address for the ChainLink VRF co-ordinator on a given chain
    VRFCoordinatorV2Interface private immutable chainlinkVrfCoordinator;

    /// @notice ChainLink VRF key hash, a.k.a gas lane on a given chain
    bytes32 private immutable vrfKeyHash;

    /// @notice VRF subscription ID  
    uint64 private immutable vrfSubscriptionID;

    /// @notice Callback gas limit for VRF 
    uint32 private immutable callbackGasLimit;

    /// @notice Emitted when new lottery user for current session is added
    event LotteryDeposit(address indexed user, uint256 deposit);

    /// @notice Emitted when new winner receives prize
    event WinnerSuccessfulWithdraw(address indexed winner, uint256 prize);

    /// @notice Emitted when owner of contract withdraws fees from Lottery Treasury
    event TreasuryFeeWithdrawal(address indexed owner, uint256 amount);

    /// @notice Error triggered if winner fails to withdraw their prize pot
    error WinnerFailedWithdrawl(); 

    /// @notice Upkeep triggered externally without the current session having expired
    error UpkeepNotRequired();

    modifier onlyPauser() {
        require(pauserRegistry.isPauser(msg.sender), "msg.sender is not authorized as a pauser");
        _;
    }

    modifier onlyUnpauser() {
        require(pauserRegistry.isUnpauser(msg.sender), "msg.sender is not authorized as an unpauser");
        _;
    }

    modifier onlyTimeValid(uint256 timeDuration) {
        require(block.timestamp - lastBlockTimestamp < timeDuration, "Invalid call, your time period has expired");
        _;
    }

    modifier onlyWinner() {
        require(currentWinner != address(0), "Address 0 is an invalid winner");
        require(msg.sender == currentWinner, "Invalid winner, you are not the current winner");
        _;
    }

    constructor(
        uint256 _lotteryDeposit, 
        uint256 _lotteryDuration, 
        uint256 _prizeExpiry,
        uint256 _expiryGap,
        address _chainlinkVrfCoordinator, 
        bytes32 _vrfKeyHash,
        uint64 _vrfSubscriptionID,
        uint32 _callbackGasLimit
    ) 
        VRFConsumerBaseV2(_chainlinkVrfCoordinator) 
    {
        require(_lotteryDuration > _prizeExpiry + _expiryGap, "LotteryContract.constructor: Insufficient gap between expiry and duration");
        lotteryDeposit = _lotteryDeposit;
        lotteryDuration = _lotteryDuration;
        prizeExpiry = _prizeExpiry;
        expiryGap = _expiryGap;
        lastBlockTimestamp = block.timestamp;
        chainlinkVrfCoordinator = VRFCoordinatorV2Interface(_chainlinkVrfCoordinator);
        vrfKeyHash = _vrfKeyHash;
        vrfSubscriptionID = _vrfSubscriptionID;
        callbackGasLimit = _callbackGasLimit;
          
        // Prevents "initialize()" from being run in the context of this contract's own storage
        _disableInitializers();
    }

    // EXTERNAL FUNCTIONS

    /**
     * @notice Initializes contract owner, pauser registry address and pausable status
     * @param _pauserRegistry Address of pauser registry contract
     * @dev Must be called by owner of "ProxyAdmin" within the "upgradeAndCall()" function via
     * "bytes memory data" argument, when setting this contract as the implementation
     * @dev Owner initialized as tx.origin, which will be owner of ProxyAdmin
     */
    function initialize(IPauserRegistry _pauserRegistry) external initializer {
        pauserRegistry = _pauserRegistry;   // Set pauser registry
        __Ownable_init(tx.origin);            // Initialize ownable with tx.origin
        __Pausable_init();                    // Initialize pausable 
        __ReentrancyGuard_init();             // Initialize reentrancyguard
        lastBlockTimestamp = block.timestamp; // Initializing lastBlockTimestamp for Proxy
    }

    /// @notice Pauses contract functionality temporarily
    function pauseContract() external onlyPauser {
        _pause();
    }

    /// @notice Unpauses contract functionality
    function unpauseContract() external onlyUnpauser {
        _unpause();
    }

    /**
     * @notice The core deposit function to enter current session's lottery
     * @dev Function is pausable (see "PauserRegistry" contract for authorized pausers/unpausers)
     */
    function enterLottery() external payable onlyTimeValid(lotteryDuration) whenNotPaused {
        require(!lotteryUsers.contains(msg.sender), "LotteryContract.enterLottery: Not allow more than 1 deposit in given session");
        require(msg.value == lotteryDeposit, "LotteryContract.enterLottery: Incorrect amount deposited");
        currentPrizePot += msg.value;
        lotteryUsers.add(msg.sender);
        emit LotteryDeposit(msg.sender, msg.value);
    }

    /**
     * @notice Anyone can trigger random winner selection provided the lottery period has
     * expired AND there is at least one player in the lottery, and the functionality is not currently paused
     */
    function performUpkeep(bytes calldata /* performData */) external whenNotPaused returns (uint256 requestId) {
        (bool upkeepNeeded, bytes32 data) = checkUpkeep("");
        if (!upkeepNeeded) {
            if (data == hex"ff") {
                lastBlockTimestamp = block.timestamp;   // If time elapsed but no users, need to update timer
            } else {
                revert UpkeepNotRequired();
            }
        } else {
            // Resets current winner before picking next
            currentWinner = payable(address(0));

            // Makes a request to the Chainlink VRF contract. Will revert if subscription is not set and funded
            requestId = chainlinkVrfCoordinator.requestRandomWords(
                vrfKeyHash,
                vrfSubscriptionID,
                REQUEST_CONFIRMATIONS,
                callbackGasLimit,
                NUM_WORDS
            );
        }
    }

    /**
     * @notice Transfers lottery winnings to current winner provided within allotted time period. If winner misses
     * deadline, their prize pot rolls over into next lottery session
     */
    function winnerWithdraw() external onlyWinner whenNotPaused onlyTimeValid(prizeExpiry) nonReentrant {
        // Checks -> Effects -> Interactions
        address payable winner = currentWinner;
        uint256 prizePayout = lotteryWinnings;
        lotteryWinnings = 0;    // Resetting snapshot
        currentPrizePot -= prizePayout;

        // 2300 gas stipend
        (bool success, ) = winner.call{gas: 2300, value: prizePayout}("");

        if (success) {
            emit WinnerSuccessfulWithdraw(winner, prizePayout);
        } else {
            revert WinnerFailedWithdrawl();
        }  
    }

    /**
     * @notice Withdrawing all of accumulated fees from Lottery Treasury
     * @dev Owner can only withdraw funds in excess of current user deposit
     */
    function withdraw(uint256 withdrawalAmount) external onlyOwner whenNotPaused {
        require(withdrawalAmount > 0, "LotteryContract.withdraw: Cannot withdraw 0 Ether");
        //must only be able to withdraw excess of total sum of current user deposits, i.e. require account.balance > sum(user deposits)
        uint256 protocolFees = address(this).balance - currentPrizePot;
        require(withdrawalAmount <= protocolFees, "LotteryContract.withdraw: Insufficient protocol funds for withdrawal amount");
        (bool success, ) = msg.sender.call{gas: 2300, value: withdrawalAmount}("");
        require(success, "LotteryContract.withdraw: Error in transfer of withdrawal amount");
        emit TreasuryFeeWithdrawal(msg.sender, withdrawalAmount);
    }

    // VIEW FUNCTIONS

    /// @notice Returns length of lottery users set
    function getLotteryUsersLength() external view returns (uint256) {
        return lotteryUsers.length();
    }

     /// @notice Returns true if user is in lottery users set, false otherwise
    function lotteryUsersContains(address user) external view returns (bool) {
        return lotteryUsers.contains(user);
    }

    /**
     * @notice Getter function for private payable address "currentWinner"
     * @dev Current (last) winner only gets updated when new winner is picked
     */
    function getCurrentWinner() external view returns (address) {
        return currentWinner;
    }

    /// @notice Getter function for private uint256 "lotteryWinnings"
    function getLotteryWinnings() external view returns (uint256) {
        return lotteryWinnings;
    }

    /// @notice Getter function for private uint256 "currentPrizePot"
    function getCurrentPrizePot() external view returns (uint256) {
        return currentPrizePot;
    }

    /// @notice Getter function for private immutable "lotteryDeposit"
    function getLotteryDeposit() external view returns (uint256) {
        return lotteryDeposit;
    }

    /// @notice Getter function for private immutable "lotteryDuration"
    function getlotteryDuration() external view returns (uint256) {
        return lotteryDuration;
    }

    /// @notice Getter function for private immutable "prizeExpiry"
    function getPrizeExpiry() external view returns (uint256) {
        return prizeExpiry;
    }

    /// @notice Getter function for private immutable "lastBlockTimestamp"
    function getLastBlockTimestamp() external view returns (uint256) {
        return lastBlockTimestamp;
    }

    /**
     * @notice Called by Chainlink automation nodes to check if it's time to perform an upkeep
     * @return upkeepNeeded bool, whether or not a new winner can be drawn (current lottery session has expired) 
     * @return performData for caller
     * @dev This function includes all the logic of a check that we would otherwise perform
     * @dev Public because we will call this function as a double-check in "performUpkeep()"
     */
    function checkUpkeep(bytes memory /* checkData */) public view returns (bool upkeepNeeded, bytes32 performData) {
        if((block.timestamp - lastBlockTimestamp) < lotteryDuration) {
            return (false, "");     // Return an empty bytes value for the unused parameter
        } else if (lotteryUsers.length() == 0) {
            return (false, hex"ff"); 
        } else {
            return (true, "");    // Similarly, return an empty bytes value 
        }
    }

    // INTERNAL FUNCTIONS

    /**
     * @notice Function to receive random number via VRF callback
     * @param _randomWords Array of VRF random numbers (our result(s))
     * @dev Chainlink node will call the VRF coordinator on given chain, who in turn will this function 
     * (via external counterpart) to provide random number
     */
    function fulfillRandomWords(uint256 /* _requestId */, uint256[] memory _randomWords) internal override whenNotPaused {
        // Bound the winning index to the number of entrants in current round
        uint256 winnerIndex = _randomWords[0] % lotteryUsers.length();
        currentWinner = payable(lotteryUsers.at(winnerIndex));

        // 50bps protocol fee subtracted from winning pot, regardless if winner claims or not
        currentPrizePot = (currentPrizePot * 995) / 1000;   

        // Snapshots session ending pot size and time
        lotteryWinnings = currentPrizePot;  // Also resets winnins in case previous winner didn't claim pot
        lastBlockTimestamp = block.timestamp;

        // Clearing entire current lottery set
        clearSet();
    }

    // PRIVATE FUNCTIONS

    /// @notice Completely clears current lottery set, potentially gas intensive
    function clearSet() private {
        uint256 length = lotteryUsers.length();
        for (uint256 i = 0; i < length;) {
            // Always remove the first element until the set is empty
            lotteryUsers.remove(lotteryUsers.at(0));
            unchecked {
                ++i;
            }
        }
    }
}