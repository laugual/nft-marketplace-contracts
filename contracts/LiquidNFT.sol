pragma ton-solidity >=0.44.0;
pragma AbiHeader time;
pragma AbiHeader pubkey;
pragma AbiHeader expire;

//================================================================================
//
import "../interfaces/ILiquidNFT.sol";

//================================================================================
//
contract LiquidNFT is ILiquidNFT
{
    //========================================
    // Constants

    //========================================
    // Variables
    address static _collectionAddress; //
    uint128 static _tokenID;           //

    //========================================
    // Modifiers
    modifier onlyRoot {    require(msg.sender.isStdAddrWithoutAnyCast() && _collectionAddress == msg.sender && _collectionAddress != addressZero, ERROR_MESSAGE_SENDER_IS_NOT_MY_ROOT);    _;    }

    //========================================
    // Getters
    function  getTokenID()           external             view         returns (uint128) {     return                      (_tokenID);              }
    function callTokenID()           external responsible view reserve returns (uint128) {     return {value: 0, flag: 128}(_tokenID);              }
    function  getCollectionAddress() external             view         returns (address) {     return                      (_collectionAddress);    }
    function callCollectionaddress() external responsible view reserve returns (address) {     return {value: 0, flag: 128}(_collectionAddress);    }

    //========================================
    //
    constructor(address ownerAddress, uint256 uploaderPubkey) public onlyRoot
    {
        require(ownerAddress != addressZero, ERROR_MESSAGE_OWNER_CAN_NOT_BE_ZERO);
        tvm.accept();
        _reserve();
        _populateInfo(ownerAddress, now);
        _uploaderPubkey = uploaderPubkey;

        // Return the change
        ownerAddress.transfer(0, true, 128);
    }
}

//================================================================================
//
