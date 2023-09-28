// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "forge-std/Test.sol";
import "src/GachaTicketNFT.sol";
import "src/EventToken.sol";

contract DeployScript is Script, Test {

    GachaTicketNFT gacha;
    EventToken eventToken;
    uint64 subId;
    address vrfAddress;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        deploy();

        vm.stopBroadcast();
    }

    function deploy() internal{
        subId = uint64(vm.envUint("SUB_ID"));
        vrfAddress = vm.envAddress("CHAINLINK_ADDRESS");
        initializeContracts();
        connectContracts();
    }

    function initializeContracts() internal virtual{
        eventToken = new EventToken();
        gacha = new GachaTicketNFT(subId, vrfAddress);
    }

    function connectContracts() internal {
        eventToken.setMinterContractAddress(address(gacha));
        gacha.setEventToken(address(eventToken));
        assertEq(eventToken.minterContractAddress(), address(gacha));
        assertEq(address(gacha.eventToken()), address(eventToken));
    }
}

// Deploy command
// forge script script/DeployScript.s.sol:DeployScript --fork-url <RPC_URL> --broadcast --verify -vvvv
