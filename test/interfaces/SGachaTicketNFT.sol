// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface SGachaTicketNFT {
    struct Person {
        address addr;
        uint256 balance;
    }

    struct Vars {
        Person owner; // オーナーアカウント
        Person[] persons; // 複数のアカウントを格納するための配列
    }
}