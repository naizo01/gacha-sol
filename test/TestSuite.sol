// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { SGachaTicketNFT } from "test/interfaces/SGachaTicketNFT.sol";
import "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import "script/DeployScript.sol";

abstract contract TestSuite is SGachaTicketNFT, DeployScript {

    Vars testVars;
    address coordinatorAddress;
    VRFCoordinatorV2Mock vrf;
    uint256 randomWord = 10;

    function prepareTestUsers() internal virtual {}

    // Simulates the generation of a random number for a given user.
    function simulateRandomNumberGenerationForUser(uint userIndex) internal {
        uint256[] memory randomNumbers = new uint256[](1);
        randomNumbers[0] = randomWord;
        vm.prank(coordinatorAddress);
        gacha.rawFulfillRandomWords(testVars.persons[userIndex].requestId, randomNumbers);
    }

    // Internal function to assert the results of a user's ticket purchase.
    function assertUserTicketPurchase(uint userIndex) internal {
        vm.prank(testVars.persons[userIndex].addr);
        gacha.mintEventTokens();
        testVars.persons[userIndex].balance = eventToken.balanceOf(testVars.persons[userIndex].addr);
        assertTrue(testVars.persons[userIndex].balance == randomWord % 50 + 1);
    }

    // Internal function to simulate a user purchasing a ticket.
    function simulateUserTicketPurchase(uint userIndex) internal virtual {}

    // Test to validate that users can purchase tickets and receive the corresponding tokens.
    function test_validateTicketPurchaseAndTokenAssignment() public {
        for (uint i = 0; i < testVars.persons.length; i++) {
            simulateUserTicketPurchase(i);
        }
    }

    // Test to ensure that only the contract owner can burn tokens.
    function test_ensureOnlyOwnerCanBurnTokens() public {
        test_validateTicketPurchaseAndTokenAssignment();
        vm.prank(testVars.persons[0].addr);
        eventToken.transfer(testVars.owner.addr, testVars.persons[0].balance);
        assertEq(eventToken.balanceOf(testVars.owner.addr), testVars.persons[0].balance);
        vm.prank(testVars.owner.addr);
        eventToken.burn(testVars.persons[0].balance);
    }

    // Test to ensure that only the contract owner can set the EventToken address.
    function test_ensureOnlyOwnerCanSetEventToken() public {
        vm.prank(testVars.persons[0].addr);
        vm.expectRevert("Ownable: caller is not the owner");
        gacha.setEventToken(address(eventToken));
    }

    // Tests that only the contract owner can set the minter contract address for the EventToken.
    function test_onlyOwnerCanSetMinterContractAddress() public {
        vm.prank(testVars.persons[0].addr);
        vm.expectRevert("Ownable: caller is not the owner");
        eventToken.setMinterContractAddress(address(eventToken));
    }

    // Test to validate that an invalid random number request is rejected.
    function test_validateInvalidRandomNumberRequest() public {
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = randomWord;
        vm.prank(coordinatorAddress);
        vm.expectRevert("request not found");
        gacha.rawFulfillRandomWords(1, randomWords);
    }

    // Test to ensure that users cannot purchase multiple tickets.
    function test_validateMultipleTicketPurchaseRestriction() public {
        test_validateTicketPurchaseAndTokenAssignment();
        vm.prank(testVars.persons[0].addr);
        vm.expectRevert("Already purchased tickets");
        gacha.buyTicketAndPlayGacha{value: 0.1 ether}();
    }

    // Test to ensure that users send the correct ether amount when purchasing a ticket.
    function test_validateEtherAmountForTicketPurchase() public {
        vm.prank(testVars.persons[0].addr);
        vm.expectRevert("Must send 0.1 ether");
        gacha.buyTicketAndPlayGacha{value: 0.01 ether}();
    }

    // Test to ensure that users cannot mint event tokens without a generated random number.
    function test_validateUserCannotMintWithoutRandomNumber() public virtual {}

    // Test to ensure that non-owners cannot burn tokens.
    function test_ensureNonOwnersCannotBurnTokens() public {
        test_validateTicketPurchaseAndTokenAssignment();
        vm.prank(testVars.persons[0].addr);
        vm.expectRevert("Ownable: caller is not the owner");
        eventToken.burn(testVars.persons[0].balance);
    }

    // Test to ensure that only the Gacha contract can mint tokens.
    function test_ensureOnlyGachaCanMintTokens() public {
        test_validateTicketPurchaseAndTokenAssignment();
        vm.prank(testVars.persons[0].addr);
        vm.expectRevert("Only minter contract can mint");
        eventToken.mint(testVars.owner.addr, 1);
    }
}