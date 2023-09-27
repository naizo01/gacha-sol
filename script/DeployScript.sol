// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "src/GachaTicketNFT.sol";
import "src/EventToken.sol";
import { GachaTests } from "test/GachaTicketNFTTests.sol";

contract DeployScript is Script, GachaTests {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        deploy();

        vm.stopBroadcast();
    }

    function deploy() internal{
        subId = uint64(vm.envUint("SUB_ID"));
        vrfAddress = vm.envAddress("CHAINLINK_ADDRESS");
        testVars.owner.addr = vm.envAddress("OWNER_ADDRESS");
        initializeContracts();
        connectContracts();
    }
}

// Deploy command
// forge script script/DeployScript.s.sol:DeployScript --fork-url <RPC_URL> --broadcast --verify -vvvv
