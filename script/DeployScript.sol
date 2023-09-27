// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "src/GachaTicketNFT.sol";
import "src/EventToken.sol";

contract DeployScript is Script {
    EventToken token;
    GachaTicketNFT gacha;

    function run() public {
        uint64 subId = uint64(vm.envUint("SUB_ID"));
        address chainLinkAddress = vm.envAddress("CHAINLINK_ADDRESS");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        token = new EventToken();
        gacha = new GachaTicketNFT(subId, chainLinkAddress);

        token.setMinterContractAddress(address(gacha));
        gacha.setEventToken(address(token));

        vm.stopBroadcast();
    }
}

// Deploy command
// forge script script/DeployScript.s.sol:DeployScript --fork-url <RPC_URL> --broadcast --verify -vvvv
