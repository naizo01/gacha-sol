// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "src/GachaTicketNFT.sol";
import "src/EventToken.sol";
import { SGachaTicketNFT } from "test/interfaces/SGachaTicketNFT.sol";
import "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

abstract contract GachaTestSetup is Test, SGachaTicketNFT {
    GachaTicketNFT gacha;
    EventToken eventToken;
    Vars testVars;
    uint64 subId;

    VRFCoordinatorV2Mock vrf;

    function initializeChainlink() internal {
        vrf = new VRFCoordinatorV2Mock(100000000000000000, 1000000000);
    }

    function initializeContracts() internal {
        testVars.owner.addr = makeAddr("Owner");
        vm.prank(testVars.owner.addr);
        eventToken = new EventToken();
        vm.prank(testVars.owner.addr);
        gacha = new GachaTicketNFT(subId, address(vrf));
    }

    function connectContracts() internal {
        vm.prank(testVars.owner.addr);
        eventToken.setMinterContractAddress(address(gacha));
        vm.prank(testVars.owner.addr);
        gacha.setEventToken(address(eventToken));
        assertEq(eventToken.minterContractAddress(), address(gacha));
        assertEq(address(gacha.eventToken()), address(eventToken));
    }

    function prepareTestUsers() internal {
        string[2] memory userNames = ["A", "B"];
        for (uint i = 0; i < userNames.length; i++) {
            SGachaTicketNFT.Person memory newUser;
            newUser.addr = makeAddr(userNames[i]);
            testVars.persons.push(newUser);
            vm.deal(newUser.addr, 10 ether);
        }
    }
}

contract GachaTests is Test, GachaTestSetup {

    uint256 randomWord = 10;

    // Initial setup for the tests, including deploying necessary contracts and preparing test users.
    function setUp() public {
        initializeChainlink();
        initializeContracts();
        connectContracts();
        prepareTestUsers();
    }

    // Internal function to simulate a user purchasing a ticket.
    function simulateUserTicketPurchase(uint userIndex) internal {
        vm.prank(testVars.persons[userIndex].addr);
        vm.mockCall(
            address(vrf),
            abi.encodeWithSelector(vrf.requestRandomWords.selector),
            abi.encode(userIndex + 1)
        );
        gacha.buyTicketAndPlayGacha{value: 2 ether}();

        assertEq(gacha.addressToRequestId(testVars.persons[userIndex].addr), userIndex + 1);
        assertEq(gacha.balanceOf(testVars.persons[userIndex].addr), 1);

        simulateRandomNumberGenerationForUser(userIndex);
        assertUserTicketPurchase(userIndex);
    }

    // Simulates the generation of a random number for a given user.
    function simulateRandomNumberGenerationForUser(uint userIndex) internal {
        uint256[] memory randomNumbers = new uint256[](1);
        randomNumbers[0] = randomWord;
        vm.prank(address(vrf));
        gacha.rawFulfillRandomWords(userIndex + 1, randomNumbers);
    }

    // Internal function to assert the results of a user's ticket purchase.
    function assertUserTicketPurchase(uint userIndex) internal {
        vm.prank(testVars.persons[userIndex].addr);
        gacha.mintEventTokens();
        testVars.persons[userIndex].balance = eventToken.balanceOf(testVars.persons[userIndex].addr);
        assertTrue(testVars.persons[userIndex].balance == randomWord % 50 + 1);
    }

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

    // Test to ensure that users cannot mint event tokens without a generated random number.
    function test_validateUserCannotMintWithoutRandomNumber() public {
        vm.prank(testVars.persons[0].addr);
        vm.mockCall(
            address(vrf),
            abi.encodeWithSelector(vrf.requestRandomWords.selector),
            abi.encode(1)
        );
        gacha.buyTicketAndPlayGacha{value: 2 ether}();
        vm.prank(testVars.persons[0].addr);
        vm.expectRevert("Random numbers are not generated");
        gacha.mintEventTokens();
    }

    // Test to validate that an invalid random number request is rejected.
    function test_validateInvalidRandomNumberRequest() public {
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = randomWord;
        vm.prank(address(vrf));
        vm.expectRevert("request not found");
        gacha.rawFulfillRandomWords(1, randomWords);
    }

    // Test to ensure that users cannot purchase multiple tickets.
    function test_validateMultipleTicketPurchaseRestriction() public {
        test_validateTicketPurchaseAndTokenAssignment();
        vm.prank(testVars.persons[0].addr);
        vm.expectRevert("Already purchased tickets");
        gacha.buyTicketAndPlayGacha{value: 2 ether}();
    }

    // Test to ensure that users send the correct ether amount when purchasing a ticket.
    function test_validateEtherAmountForTicketPurchase() public {
        vm.prank(testVars.persons[0].addr);
        vm.expectRevert("Must send 2 ether");
        gacha.buyTicketAndPlayGacha{value: 1 ether}();
    }

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
        eventToken.mint(testVars.persons[1].addr, 1);
    }
}