//SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "./nnsNftResolver.sol";
import "./interfaces/IERC6551Registry.sol";

// hyperlaneImports  //////////
import {IInterchainSecurityModule, ISpecifiesInterchainSecurityModule} from "./imports/IInterchainSecurityModule.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import { ByteHasher } from './imports/ByteHasher.sol';


interface IMailbox 
{
    function dispatch(
        uint32 _destination,
        bytes32 _recipient,
        bytes calldata _body
    ) external returns (bytes32);
}

interface IInterchainGasPaymaster 
{
    /**
     * @notice Deposits msg.value as a payment for the relaying of a message
     * to its destination chain.
     * @dev Overpayment will result in a refund of native tokens to the _refundAddress.
     * Callers should be aware that this may present reentrancy issues.
     * @param _messageId The ID of the message to pay for.
     * @param _destinationDomain The domain of the message's destination chain.
     * @param _gasAmount The amount of destination gas to pay for.
     * @param _refundAddress The address to refund any overpayment to.
     */
    function payForGas(
        bytes32 _messageId,
        uint32 _destinationDomain,
        uint256 _gasAmount,
        address _refundAddress
    ) external payable;

    /**
     * @notice Quotes the amount of native tokens to pay for interchain gas.
     * @param _destinationDomain The domain of the message's destination chain.
     * @param _gasAmount The amount of destination gas to pay for.
     * @return The amount of native tokens required to pay for interchain gas.
     */
    function quoteGasPayment(uint32 _destinationDomain, uint256 _gasAmount)
        external
        view
        returns (uint256);
}

interface IMessageRecipient 
{
    function handle(
        uint32 _origin, //Domain id of the sender chain
        bytes32 _sender,
        bytes calldata _body
    ) external;
}

interface Messenger 
{
    function sendMessage(
        address _target,
        bytes memory _message,
        uint32 _gasLimit
    ) external;
}



interface interfaceNnsNftResolver
{
    function setNpcAccountAddress(address paramNpcAccountAddress) external;
}

contract nnsRegistry
{
    event nneCreatedAndRegistered(string name, address namedNpcAddress, address npcAccountAddress);

    //Hyperlane///
    using ByteHasher for bytes;

    uint256 gasAmount = 300000;
    address MAILBOX = 0xCC737a94FecaeC165AbCf12dED095BB13F037685; //SAME ON ALL CHAINS.///
    IInterchainGasPaymaster igp = IInterchainGasPaymaster(0x8f9C3888bFC8a5B25AED115A82eCbb788b196d2a); ////// iGasPaymaster on thisChain (default, same all chains) /////

    IInterchainSecurityModule public interchainSecurityModule = IInterchainSecurityModule(address(0));




    uint32 public destinationChainDomain;
    address public destinationNnsRegistry;

    address public owner;

    address public erc6551Implementation;
    address public erc6551Registry;

    uint public saltCounter;

    nnsNftResolver[] public nnsNftContractArray;

    mapping(string => address) resolverNfts;
    mapping(string => bool) isRegistered;
    mapping(string => uint) entityOriginChain;


    constructor(address paramImplementationAddress, address paramRegistryAddress)
    {
        owner = msg.sender;
        
        erc6551Implementation = paramImplementationAddress;
        erc6551Registry = paramRegistryAddress;
    }

    function createNewNamedNpcEntity(string memory paramNameToRegister) public
    {
        require(!isRegistered[paramNameToRegister], "Name already registered.");


        nnsNftResolver newNftResolver = new nnsNftResolver(paramNameToRegister, msg.sender);

        nnsNftContractArray.push(newNftResolver);

        address newNftResolverAddr = newNftResolver.getNpcAddress();

        address namedNpcAccount =  IERC6551Registry(erc6551Registry).createAccount(erc6551Implementation, block.chainid, newNftResolverAddr, 0, saltCounter, "");

        interfaceNnsNftResolver(namedNpcAccount).setNpcAccountAddress(namedNpcAccount);
    


        //CROSS_CHAIN_REGISTRATION
        resolverNfts[paramNameToRegister] = newNftResolverAddr;
        isRegistered[paramNameToRegister] = true;
        entityOriginChain[paramNameToRegister] = block.chainid; 

        makeCcCall(destinationChainDomain, destinationNnsRegistry, paramNameToRegister, newNftResolverAddr, block.chainid);  



        emit nneCreatedAndRegistered(paramNameToRegister, newNftResolverAddr, namedNpcAccount);
    }





    modifier onlyMailbox() 
    {
        require(msg.sender == MAILBOX);
        _;    
    }

    function setCcRegistryData(uint32 paramChainDomain, address paramDestinationRegistry) public 
    {
        require(msg.sender == owner, "Not owner.");

        destinationChainDomain = paramChainDomain;
        destinationNnsRegistry = paramDestinationRegistry;
    }

    function bytes32ToAddress(bytes32 _buf) internal pure returns (address) 
    {
        return address(uint160(uint256(_buf)));
    }

    function addressToBytes32(address _addr) internal pure returns (bytes32) 
    {
        return bytes32(uint256(uint160(_addr)));
    }

    function makeCcCall
    (
        uint32 paramDestinationChainDomain, 
        address paramDestinationChainAddressReceiver,
        string memory paramNameToRegister,
        address newNftResolverAddr,
        uint originChainId
    ) 
    public payable
    {
        bytes memory encodedValue = abi.encode(paramNameToRegister, newNftResolverAddr, originChainId);

        bytes32 messageId = IMailbox(MAILBOX).dispatch(
            paramDestinationChainDomain,
            addressToBytes32(paramDestinationChainAddressReceiver),
            encodedValue
        );

        igp.payForGas{ value: msg.value }(
            messageId, // The ID of the message that was just dispatched
            paramDestinationChainDomain, // The destination domain of the message
            1200000,
            address(tx.origin) // refunds are returned to transaction executer
        );
    }

    function handle(uint32 _origin, bytes32 _sender, bytes calldata _body) external onlyMailbox 
    {
        string memory nameToRegister;
        address nftResolverAddr;
        uint originChainId;

        (nameToRegister, nftResolverAddr, originChainId) = abi.decode(_body, (string, address, uint));
        
    }
}