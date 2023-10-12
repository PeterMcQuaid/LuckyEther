// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {EmptyContract} from "../../src/test/mocks/EmptyContract.sol";

contract EmptyContractTest is Test {
    EmptyContract emptyContract;

    function setUp() external {
        emptyContract = new EmptyContract();
    }

    function test_EmptyFunctionReturnsZero() external {
        assertEq(emptyContract.emptyFunction(), 0);
    }
}

