// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./EventToken.sol";

/**
 * @title GachaTicketNFT
 * @dev This contract represents a Gacha ticket as an ERC721 token. 
 * Users can buy a ticket and play Gacha to receive EventTokens.
 */
contract GachaTicketNFT is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    EventToken public eventToken;
    mapping(address => bool) public hasTicket;

    /**
     * @dev Constructor that sets the name and symbol for the NFT.
     */
    constructor() ERC721("GachaTicket", "GTNFT") {}

    /**
     * @notice Sets the address of the EventToken contract.
     * @dev Only the owner of this contract can set the EventToken address.
     * @param _eventToken The address of the EventToken contract.
     */
    function setEventToken(address _eventToken) external onlyOwner {
        eventToken = EventToken(_eventToken);
    }

    /**
     * @notice Allows users to buy a Gacha ticket and play Gacha to receive EventTokens.
     * @dev Users must send exactly 2 ether and cannot have bought a ticket before.
     */
    function buyTicketAndPlayGacha() external payable {
        require(msg.value == 2 ether, "Must send 2 ether");
        require(!hasTicket[msg.sender], "Already purchased tickets");

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _mint(msg.sender, newTokenId);

        uint256 randomSeed = uint256(keccak256(abi.encodePacked(msg.sender, block.number, newTokenId)));
        uint256 randomTokenAmount = (randomSeed % 50) + 1;
        eventToken.mint(msg.sender, randomTokenAmount);

        hasTicket[msg.sender] = true;
    }
}
