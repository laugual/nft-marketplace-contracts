pragma ton-solidity >=0.44.0;
pragma AbiHeader time;
pragma AbiHeader pubkey;
pragma AbiHeader expire;

//================================================================================
//
import "../contracts/LiquidNFT.sol";

//================================================================================
//
contract LiquidNFTCollection is ILiquidNFT
{    //========================================
    // Constants

    //========================================
    // Variables
    bytes   static _collectionName; //
    TvmCell static _tokenCode;      //
    uint128        _tokensIssued;   //
    address        _externalMedia;  //

    //========================================
    // Modifiers

    //========================================
    // Getters
    function   getTokenCode()     external view                     returns (TvmCell) {    return                      (_tokenCode     );    }
    function  callTokenCode()     external responsible view reserve returns (TvmCell) {    return {value: 0, flag: 128}(_tokenCode     );    }
    function   getTokensIssued()  external view                     returns (uint128) {    return                      (_tokensIssued  );    }
    function  callTokensIssued()  external responsible view reserve returns (uint128) {    return {value: 0, flag: 128}(_tokensIssued  );    }
    function  getCollectionName() external view                     returns (bytes  ) {    return                      (_collectionName);    }
    function callCollectionName() external responsible view reserve returns (bytes  ) {    return {value: 0, flag: 128}(_collectionName);    }

    //========================================
    //
    function calculateFutureNFTAddress(uint128 tokenID) private inline view returns (address, TvmCell)
    {
        TvmCell stateInit = tvm.buildStateInit({
            contr: LiquidNFT,
            varInit: {
                _collectionAddress: address(this),
                _tokenID:           tokenID
            },
            code: _tokenCode
        });

        return (address(tvm.hash(stateInit)), stateInit);
    }

    //========================================
    //
    constructor(address ownerAddress, uint256 uploaderPubkey) public
    {
        require(ownerAddress != addressZero, ERROR_MESSAGE_OWNER_CAN_NOT_BE_ZERO);
        tvm.accept();
        _reserve();
        _populateInfo(ownerAddress, now);

        _uploaderPubkey = uploaderPubkey;        
        _tokensIssued   = 0;
        
        // Return the change
        ownerAddress.transfer(0, true, 128);
    }

    //========================================
    //
    function createEmptyNFT(uint256 uploaderPubkey) external onlyOwner isSealed reserve
    {
        ( , TvmCell stateInit) = calculateFutureNFTAddress(_tokensIssued);
        new LiquidNFT{value: 0, flag: 128, stateInit: stateInit}(_info.ownerAddress, uploaderPubkey);

        _tokensIssued += 1;
    }
}

//================================================================================
//
