// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "src/GachaTicketNFT.sol";
import "src/EventToken.sol";
import { GachaTests } from "./GachaTicketNFTTests.sol";
import { SGachaTicketNFT } from "test/interfaces/SGachaTicketNFT.sol";
import "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract ForkTest is GachaTests {
    uint256 spepoliaFork;

    function initializeRpc() internal {
        string memory rpcUrl = vm.envString("SPEPOLIA_RPC_URL");
        spepoliaFork = vm.createSelectFork(rpcUrl);
    }

    function initializeContracts() internal override {
        address _eventToken = vm.envAddress("EVENT_TOKEN_ADDRESS");
        address _gacha = vm.envAddress("GACHA_ADDRESS");
        address _vrf = vm.envAddress("VRF_ADDRESS");
        coordinatorAddress = vm.envAddress("VRF_COORDINATOR_ADDRESS");
        eventToken = EventToken(_eventToken);
        gacha = GachaTicketNFT(_gacha);
        vrf = VRFCoordinatorV2Mock(_vrf);
    }

    function prepareTestUsers() internal override {
        testVars.owner.addr = vm.envAddress("OWNER_ADDRESS");
        SGachaTicketNFT.Person memory newUser;
        newUser.addr = vm.envAddress("TEST_ADDRESS1");
        testVars.persons.push(newUser);
        vm.deal(newUser.addr, 10 ether);
    }

}

contract GachaForkTests is ForkTest {

    function setUp() public override {
        prepareTestUsers();
        initializeRpc();
        initializeContracts();
    }

    // Internal function to simulate a user purchasing a ticket.
    function simulateUserTicketPurchase(uint userIndex) internal override {
        vm.prank(testVars.persons[userIndex].addr);
        gacha.buyTicketAndPlayGacha{value: 0.1 ether}();

        testVars.persons[userIndex].requestId = gacha.addressToRequestId(testVars.persons[userIndex].addr);
        assertEq(gacha.balanceOf(testVars.persons[userIndex].addr), 1);

        simulateRandomNumberGenerationForUser(userIndex);
        assertUserTicketPurchase(userIndex);
    }

    // Test to ensure that users cannot mint event tokens without a generated random number.
    function test_validateUserCannotMintWithoutRandomNumber() public override {
        vm.prank(testVars.persons[0].addr);
        gacha.buyTicketAndPlayGacha{value: 0.1 ether}();
        vm.prank(testVars.persons[0].addr);
        vm.expectRevert("Random numbers are not generated");
        gacha.mintEventTokens();
    }
}