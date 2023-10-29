//SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract nnsNftResolver is ERC721
{
    address public registry;
    address public linkedNpcAccountAddress;


    constructor(string memory paramNpcEntityName, address paramOwner) ERC721(paramNpcEntityName, paramNpcEntityName)
    {
        registry = msg.sender;
        _safeMint(paramOwner, 0);
    }



    function setNpcAccountAddress(address paramNpcAccountAddress) public
    {
        require(msg.sender == registry, "Not registry.");
        linkedNpcAccountAddress = paramNpcAccountAddress;
    }

    function npcEntityName() public view returns(string memory)
    {
        return(name());
    }

    function currentOwner() public view returns(address)
    {
        return(ownerOf(0));
    }

    function transferNpcNameNft(address paramTo) public
    {
        require(msg.sender == ownerOf(0));
        safeTransferFrom(msg.sender, paramTo, 0);
    }

    function getNpcAddress() public view returns(address)
    {
        return address(this);
    }
}