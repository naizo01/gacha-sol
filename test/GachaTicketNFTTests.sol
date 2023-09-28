// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import { SGachaTicketNFT } from "test/interfaces/SGachaTicketNFT.sol";
import { TestSuite } from "test/TestSuite.sol";


contract GachaTestSetup is TestSuite {

    function initializeChainlink() internal {
        vrf = new VRFCoordinatorV2Mock(100000000000000000, 1000000000);
        coordinatorAddress = address(vrf);
        vrfAddress = address(vrf);
    }

    function prepareTestUsers() internal override{
        testVars.owner.addr = makeAddr("Owner");
        string[2] memory userNames = ["A", "B"];
        for (uint i = 0; i < userNames.length; i++) {
            SGachaTicketNFT.Person memory newUser;
            newUser.addr = makeAddr(userNames[i]);
            testVars.persons.push(newUser);
            vm.deal(newUser.addr, 10 ether);
        }
    }

}

contract GachaTests is GachaTestSetup {

    // Initial setup for the tests, including deploying necessary contracts and preparing test users.
    function setUp() public {
        prepareTestUsers();
        
        vm.startPrank(testVars.owner.addr);

        initializeChainlink();
        initializeContracts();
        connectContracts();

        vm.stopPrank();
    }

    // Internal function to simulate a user purchasing a ticket.
    function simulateUserTicketPurchase(uint userIndex) internal override {
        vm.prank(testVars.persons[userIndex].addr);
        vm.mockCall(
            address(vrf),
            abi.encodeWithSelector(vrf.requestRandomWords.selector),
            abi.encode(userIndex + 1)
        );
        gacha.buyTicketAndPlayGacha{value: 0.1 ether}();

        testVars.persons[userIndex].requestId = gacha.addressToRequestId(testVars.persons[userIndex].addr);
        assertEq(gacha.addressToRequestId(testVars.persons[userIndex].addr), userIndex + 1);
        assertEq(gacha.balanceOf(testVars.persons[userIndex].addr), 1);

        simulateRandomNumberGenerationForUser(userIndex);
        assertUserTicketPurchase(userIndex);
    }

    // Test to ensure that users cannot mint event tokens without a generated random number.
    function test_validateUserCannotMintWithoutRandomNumber() public override {
        vm.prank(testVars.persons[0].addr);
        vm.mockCall(
            address(vrf),
            abi.encodeWithSelector(vrf.requestRandomWords.selector),
            abi.encode(1)
        );
        gacha.buyTicketAndPlayGacha{value: 0.1 ether}();
        vm.prank(testVars.persons[0].addr);
        vm.expectRevert("Random numbers are not generated");
        gacha.mintEventTokens();
    }

}