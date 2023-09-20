// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title EventToken
 * @dev This contract represents a custom ERC20 token with additional functionality 
 * to allow minting by a specific contract and burning by the owner.
 */
contract EventToken is ERC20, Ownable {
    address public minterContractAddress;

    /**
     * @dev Constructor that sets the name and symbol for the token.
     */
    constructor() ERC20("EventToken", "EVT") {}

    /**
     * @notice Sets the address of the contract that is allowed to mint tokens.
     * @dev Only the owner of this contract can set the minter contract address.
     * @param _contract The address of the contract that should be allowed to mint tokens.
     */
    function setMinterContractAddress(address _contract) public onlyOwner {
        minterContractAddress = _contract;
    }

    /**
     * @notice Mints tokens to a given address.
     * @dev Only the minter contract can mint tokens.
     * @param to The address to receive the minted tokens.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint256 amount) external {
        require(msg.sender == minterContractAddress, "Only minter contract can mint");
        _mint(to, amount);
    }

    /**
     * @notice Burns tokens from the owner's balance.
     * @dev Only the owner can burn tokens.
     * @param amount The amount of tokens to burn.
     */
    function burn(uint256 amount) external onlyOwner {
        _burn(msg.sender, amount);
    }
}
