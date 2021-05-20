pragma ton-solidity >=0.43.0;
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
    //constructor(address ownerAddress, bytes extension, bytes contents, bytes name, bytes comment) public
    constructor(address ownerAddress) public
    {
        require(ownerAddress != addressZero, ERROR_MESSAGE_OWNER_CAN_NOT_BE_ZERO);
        tvm.accept();
        _reserve();
        _populateInfo(ownerAddress, now);
        
        _tokensIssued  = 0;
        
        // Return the change
        ownerAddress.transfer(0, true, 128);
    }

    //========================================
    //
    function createEmptyNFT() public onlyOwner isSealed
    {
        _reserve();

        // TODO
        ( , TvmCell stateInit) = calculateFutureNFTAddress(_tokensIssued);
        //new LiquidNFT{value: 0, flag: 128, stateInit: stateInit}(_info.ownerAddress, extension, contents, name, comment);
        new LiquidNFT{value: 0, flag: 128, stateInit: stateInit}(_info.ownerAddress);

        _tokensIssued += 1;
    }

    //========================================
    //
    /*function createNFT(bytes extension, bytes[] contents, bytes name, bytes comment) public onlyOwner
    {
        _reserve();

        // TODO
        ( , TvmCell stateInit) = calculateFutureNFTAddress(_tokensIssued);
        new LiquidNFT{value: 0, flag: 128, stateInit: stateInit}(_info.ownerAddress, extension, contents, name, comment);

        _tokensIssued += 1;
    }*/

    //========================================
    //
    /*function createNFTFromExternal(address addressExternalMedia) public onlyOwner
    {
        _reserve();
        _externalMedia = addressExternalMedia;
        IMediaProducer(addressExternalMedia).getMedia{value: 0, callback: callbackOnCreateNFTFromExternal, flag: 128}();
    }

    function callbackOnCreateNFTFromExternal(nftMedia media) public onlyExternalMedia
    {
        _externalMedia = addressZero;
        createNFT(media.extension, media.contents, media.name, media.comment);
    }*/

    //========================================
    //
    /*onBounce(TvmSlice slice) external 
    {
		uint32 func = slice.decode(uint32);
		if(func == tvm.functionId(createNFTFromExternal)) 
        {
            _externalMedia = addressZero;
        }
    }*/
}

//================================================================================
//
