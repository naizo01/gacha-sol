// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./EventToken.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

contract GachaTicketNFT is ERC721, Ownable, VRFConsumerBaseV2 {
    using Counters for Counters.Counter;

    // State variables
    Counters.Counter private _tokenIds;
    Counters.Counter private _requestId;
    EventToken public eventToken;
    VRFCoordinatorV2Interface COORDINATOR;
    bytes32 keyHash = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;
    uint64 s_subscriptionId;
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;

    // Structs
    struct RequestStatus {
        bool fulfilled;
        uint256[] randomWords;
        address userAddress;
    }

    // Mappings
    mapping(address => uint256) public addressToRequestId;
    mapping(uint256 => RequestStatus) public requestStatuses;

    // Events
    event RequestSent(uint256 requestId, address userAddress);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    // Constructor
    constructor(uint64 subscriptionId, address vrf)
        ERC721("GachaTicket", "GTNFT")
        VRFConsumerBaseV2(vrf)
    {
        COORDINATOR = VRFCoordinatorV2Interface(vrf);
        s_subscriptionId = subscriptionId;
    }

    // External functions

    /**
     * @dev Allows the owner to set the EventToken address.
     * @param _eventToken Address of the EventToken contract.
     */
    function setEventToken(address _eventToken) external onlyOwner {
        eventToken = EventToken(_eventToken);
    }

    /**
     * @dev Allows users to buy a ticket and play the Gacha game.
     */
    function buyTicketAndPlayGacha() external payable {
        require(msg.value == 2 ether, "Must send 2 ether");
        require(addressToRequestId[msg.sender] == 0, "Already purchased tickets");

        uint256 requestId = requestRandomWords();
        mintTicket();

        emit RequestSent(requestId, msg.sender);
    }

    /**
     * @dev Allows users to mint event tokens based on the random number generated.
     */
    function mintEventTokens() external {
        uint256 requestId = addressToRequestId[msg.sender];
        require(requestStatuses[requestId].userAddress == msg.sender, "Different from the user who requested the random number");
        require(requestStatuses[requestId].fulfilled, "Random numbers are not generated");
        uint256 randomTokenAmount = (requestStatuses[requestId].randomWords[0] % 50) + 1;
        eventToken.mint(msg.sender, randomTokenAmount);
    }

    /**
     * @dev Requests random words from the Chainlink VRF.
     * @return requestId The ID of the random word request.
     */
    function requestRandomWords() internal returns (uint256 requestId) {
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        requestStatuses[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            fulfilled: false,
            userAddress: msg.sender
        });
        addressToRequestId[msg.sender] = requestId;
    }

    /**
     * @dev Mints a new Gacha ticket for the sender.
     */
    function mintTicket() internal {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _mint(msg.sender, newTokenId);
    }

    /**
     * @dev Callback function to handle the random words provided by Chainlink VRF.
     * @param requestId The ID of the random word request.
     * @param randomWords The random words provided by Chainlink VRF.
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        require(requestStatuses[requestId].userAddress != address(0), "request not found");
        requestStatuses[requestId].fulfilled = true;
        requestStatuses[requestId].randomWords = randomWords;

        emit RequestFulfilled(requestId, randomWords);
    }
}
