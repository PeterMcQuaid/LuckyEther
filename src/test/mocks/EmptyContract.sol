// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/**
 * @title Dummy contract set as initial implementation contract to be upgraded
 * @author Peter Raymond McQuaid
 */
contract EmptyContract {
    function emptyFunction() external pure returns (uint256) {
        return 0;
    }
}