// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "src/GachaTicketNFT.sol";
import "src/EventToken.sol";
import { SCachaTicketNFT } from "test/interfaces/SCachaTicketNFT.sol";

abstract contract GachaTestSetup is Test, SCachaTicketNFT {
    GachaTicketNFT gacha;
    EventToken eventToken;
    Vars testVars;

    function deployContracts() internal {
        testVars.owner.addr = makeAddr("Owner");
        vm.prank(testVars.owner.addr);
        eventToken = new EventToken();
        vm.prank(testVars.owner.addr);
        gacha = new GachaTicketNFT();
    }

    function linkContracts() internal {
        vm.prank(testVars.owner.addr);
        eventToken.setMinterContractAddress(address(gacha));
        vm.prank(testVars.owner.addr);
        gacha.setEventToken(address(eventToken));
        assertEq(eventToken.minterContractAddress(), address(gacha));
        assertEq(address(gacha.eventToken()), address(eventToken));
    }

    function setupTestAccounts() internal {
        string[30] memory userNames = [
            "A", "B", "C", "D", "E", 
            "F", "G", "H", "I", "J",
            "K", "L", "M", "N", "O",
            "P", "Q", "R", "S", "T",
            "U", "V", "W", "X", "Y",
            "Z", "AA", "BA", "CA", "DA"
        ];

        for (uint i = 0; i < userNames.length; i++) {
            SCachaTicketNFT.Person memory newUser;
            newUser.addr = makeAddr(userNames[i]);
            testVars.persons.push(newUser);
            vm.deal(newUser.addr, 10 ether);
        }
    }
}

contract GachaTests is Test, GachaTestSetup { 

    function setUp() public {
        deployContracts();
        linkContracts();
        setupTestAccounts();
    }

    // Ensure only the contract owner can set the EventToken address
    function testOwnerRightsForSettingEventToken() public {
        vm.prank(testVars.persons[0].addr);
        vm.expectRevert("Ownable: caller is not the owner");
        gacha.setEventToken(address(eventToken));
    }

    // Ensure users can purchase a ticket and receive event tokens
    function testTicketPurchaseAndTokenReception() public {
      for (uint i = 0; i < testVars.persons.length; i++) {
          vm.prank(testVars.persons[i].addr);
          gacha.buyTicketAndPlayGacha{value: 2 ether}();

          assertTrue(gacha.hasTicket(testVars.persons[i].addr));
          assertEq(gacha.balanceOf(testVars.persons[i].addr), 1);
          testVars.persons[i].balance = eventToken.balanceOf(testVars.persons[i].addr);
          assertTrue(testVars.persons[i].balance <= 50 && testVars.persons[i].balance >= 1);
      }
    }

    // Ensure users cannot purchase multiple tickets
    function testMultipleTicketPurchaseRestriction() public {
        testTicketPurchaseAndTokenReception();

        vm.prank(testVars.persons[0].addr);
        vm.expectRevert("Already purchased tickets");
        gacha.buyTicketAndPlayGacha{value: 2 ether}();
    }

    // Ensure users send the correct ether amount for ticket purchase
    function testCorrectEtherAmountForTicket() public {
        vm.prank(testVars.persons[0].addr);
        vm.expectRevert("Must send 2 ether");
        gacha.buyTicketAndPlayGacha{value: 1 ether}();
    }

    // Ensure only the owner can burn tokens
    function testOwnerRightsForTokenBurn() public {
        testTicketPurchaseAndTokenReception();
        vm.prank(testVars.persons[0].addr);
        eventToken.transfer(testVars.owner.addr, testVars.persons[0].balance);
        assertEq(eventToken.balanceOf(testVars.owner.addr), testVars.persons[0].balance);
        vm.prank(testVars.owner.addr);
        eventToken.burn(testVars.persons[0].balance);
    }

    // Ensure non-owners cannot burn tokens
    function testNonOwnerTokenBurnRestriction() public {
        testTicketPurchaseAndTokenReception();
        vm.prank(testVars.persons[0].addr);
        vm.expectRevert("Ownable: caller is not the owner");
        eventToken.burn(testVars.persons[0].balance);
    }

    // Ensure only the Gacha contract can mint tokens
    function testMintingRestriction() public {
        testTicketPurchaseAndTokenReception();
        vm.prank(testVars.persons[0].addr);
        vm.expectRevert("Only minter contract can mint");
        eventToken.mint(testVars.persons[1].addr, 1);
    }
}
