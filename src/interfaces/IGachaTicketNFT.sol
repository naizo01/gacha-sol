// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IGachaTicketNFT {
    function setEventToken(address _eventToken) external;
    function buyTicketAndPlayGacha() external payable;
    function mintEventTokens() external;
}