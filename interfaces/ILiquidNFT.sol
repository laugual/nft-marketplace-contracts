pragma ton-solidity >=0.44.0;
pragma AbiHeader time;
pragma AbiHeader pubkey;
pragma AbiHeader expire;

//================================================================================
//
struct nftInfo
{
    uint32  dtCreated;     //
    address ownerAddress;  //
    address authorAddress; //
}

struct nftMedia
{
    bytes[] contents;  // Binary file in Base64;    
    bytes   extension; // File extension, e.g. "gif" or "png" OR file description like "hash" or "link";
    bytes   name;      // (optional) NFT name,    author gives NFT a name    when created;
    bytes   comment;   // (optional) NFT comment, author gives NFT a comment when created;
    bool    isSealed;  //
}

//================================================================================
//
interface IMediaProducer
{
    function getMedia() external view responsible returns (nftMedia);
}

//================================================================================
//
abstract contract ILiquidNFT
{
    //========================================
    // Constants
    address constant addressZero = address.makeAddrStd(0, 0);

    //========================================
    // Error codes
    uint constant ERROR_MESSAGE_SENDER_IS_NOT_MY_OWNER       = 100;
    uint constant ERROR_MESSAGE_SENDER_IS_NOT_MY_ROOT        = 101;
    uint constant ERROR_MESSAGE_SENDER_IS_NOT_MY_UPLOADER    = 102;
    uint constant ERROR_MESSAGE_SENDER_IS_NOT_EXTERNAL_MEDIA = 103;
    uint constant ERROR_MESSAGE_OWNER_CAN_NOT_BE_ZERO        = 104;
    uint constant ERROR_NOT_ENOUGH_BALANCE                   = 201;
    uint constant ERROR_MEDIA_IS_SEALED                      = 202;
    uint constant ERROR_MEDIA_IS_NOT_SEALED                  = 203;
    uint constant ERROR_PART_OUT_OF_RANGE                    = 204;

    //========================================
    // Variables
    nftInfo  _info;           //
    nftMedia _media;          //
    uint256  _uploaderPubkey; //

    //========================================
    // Modifiers
    function _reserve() internal inline view {    tvm.rawReserve(gasToValue(100000, 0), 0);    }

    modifier onlyOwner   {    require(msg.sender.isStdAddrWithoutAnyCast() && _info.ownerAddress == msg.sender && _info.ownerAddress != addressZero, ERROR_MESSAGE_SENDER_IS_NOT_MY_OWNER);       _;    }
    modifier onlyUploader{    require(msg.pubkey() == _uploaderPubkey      && _uploaderPubkey    != 0,                                               ERROR_MESSAGE_SENDER_IS_NOT_MY_UPLOADER);    _;    }
    modifier isSealed    {    require(_media.isSealed == true,  ERROR_MEDIA_IS_NOT_SEALED);    _;    }
    modifier isNotSealed {    require(_media.isSealed == false, ERROR_MEDIA_IS_SEALED    );    _;    }
    modifier reserve     {    _reserve();    _;                                                      }
    modifier returnChange{                   _; msg.sender.transfer(0, true, 128);                   }

    //========================================
    // Getters
    function  getInfo()           external             view         returns (nftInfo)  {    return                      (_info );             }
    function callInfo()           external responsible view reserve returns (nftInfo)  {    return {value: 0, flag: 128}(_info );             }
    function  getMedia()          external             view         returns (nftMedia) {    return                      (_media);             }
    function callMedia()          external responsible view reserve returns (nftMedia) {    return {value: 0, flag: 128}(_media);             }
    function  getOwnerAddress()   external             view         returns (address)  {    return                      (_info.ownerAddress); }
    function callOwnerAddress()   external responsible view reserve returns (address)  {    return {value: 0, flag: 128}(_info.ownerAddress); }
    function  getUploaderPubkey() external             view         returns (uint256)  {    return                      (_uploaderPubkey);    }
    function callUploaderPubkey() external responsible view reserve returns (uint256)  {    return {value: 0, flag: 128}(_uploaderPubkey);    }

    //========================================
    //
    function changeOwner(address newOwnerAddress) external onlyOwner isSealed reserve returnChange
    {
        _info.ownerAddress = newOwnerAddress;
    }

    function callChangeOwner(address newOwnerAddress) external responsible onlyOwner isSealed returns (address)
    {
        _reserve();
        _info.ownerAddress = newOwnerAddress;

        // Return the change
        return {value: 0, flag: 128}(newOwnerAddress);
    }

    //========================================
    //
    function sealMedia(bytes extension, bytes name, bytes comment) external onlyOwner isNotSealed
    {
        _media.extension = extension;
        _media.name      = name;
        _media.comment   = comment;
        _uploaderPubkey  = 0;
        _media.isSealed  = true;
    }

    //========================================
    //
    function _populateInfo(address ownerAddress, uint32 dtCreated) internal
    {
        _info.ownerAddress  = ownerAddress;
        _info.authorAddress = ownerAddress;
        _info.dtCreated     = dtCreated;
    }

    //========================================
    //
    function _setMediaPart(uint256 partNum, uint256 partsTotal, bytes data) internal
    {
        // Recreate media with correct number of parts if needed;
        if(_media.contents.length != partsTotal)
        {
            delete _media.contents;
            _media.contents = new bytes[](partsTotal);
        }
        _media.contents[partNum] = data;
    }

    //========================================
    //
    function setMediaPart(uint256 partNum, uint256 partsTotal, bytes data) external onlyOwner isNotSealed reserve returnChange
    {
        _setMediaPart(partNum, partsTotal, data);
    }

    //========================================
    //
    function setMediaPartExternal(uint256 partNum, uint256 partsTotal, bytes data) external onlyUploader isNotSealed
    {
        tvm.accept();
        _setMediaPart(partNum, partsTotal, data);
    }

    //========================================
    //
    function touch() external view onlyOwner reserve returnChange
    { }
}

//================================================================================
//
