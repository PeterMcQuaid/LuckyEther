// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {LinkToken} from "../mocks/LinkToken.sol";

contract LinkTokenTest is Test {
    LinkToken linkToken;

    uint256 constant INITIAL_SUPPLY = 1000000000000000000000000;
    uint8 constant DECIMALS = 18;

    event Transfer(address indexed from, address indexed to, uint256 value, bytes data);

    function setUp() external {
        vm.prank(msg.sender);
        linkToken = new LinkToken();
    }

    function test_InitialSupply() external {
        assertEq(linkToken.totalSupply(), INITIAL_SUPPLY);
    }

    function test_InitialAllocation() external {
        assertEq(linkToken.balanceOf(msg.sender), INITIAL_SUPPLY);
    }

    function test_TransferAndCallEmit() external {
        address recipient = makeAddr("recipient");
        uint256 amount = 100;
        bytes memory data = "";
        vm.expectEmit(true, true, false, true, address(linkToken));
        emit Transfer(msg.sender, recipient, amount, data);
        vm.prank(msg.sender);
        linkToken.transferAndCall(recipient, amount, data);
    }
}