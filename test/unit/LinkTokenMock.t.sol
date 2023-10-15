// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {LinkToken} from "../mocks/LinkToken.sol";

contract LinkTokenTest is Test {
    LinkToken linkToken;

    uint256 constant INITIAL_SUPPLY = 1000000000000000000000000;
    uint8 constant DECIMALS = 18;

    event Transfer(address indexed from, address indexed to, uint256 value, bytes data);

    modifier skipFork() {
        if (block.chainid == 31337) {
            _;
        } else {
            return;
        }
    }

    function setUp() external {
        vm.prank(0xfeACBb053CCcF794bF2810f0D08A46CC52EDBDf3);
        linkToken = new LinkToken();
    }

    function test_InitialSupply() external skipFork {
        assertEq(linkToken.totalSupply(), INITIAL_SUPPLY);
    }

    function test_InitialAllocation() external skipFork {
        assertEq(linkToken.balanceOf(msg.sender), INITIAL_SUPPLY);
    }

    function test_TransferAndCallEmit() external skipFork {
        address recipient = makeAddr("recipient");
        uint256 amount = 100;
        bytes memory data = "";
        vm.expectEmit(true, true, false, true, address(linkToken));
        emit Transfer(msg.sender, recipient, amount, data);
        vm.prank(msg.sender);
        linkToken.transferAndCall(recipient, amount, data);
    }
}