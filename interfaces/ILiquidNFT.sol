pragma ton-solidity >=0.43.0;
pragma AbiHeader time;
pragma AbiHeader pubkey;
pragma AbiHeader expire;

//================================================================================
//
struct nftInfo
{
    uint32  dtCreated;    //
    address ownerAddress; //
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
    uint constant ERROR_MESSAGE_SENDER_IS_NOT_EXTERNAL_MEDIA = 102;
    uint constant ERROR_MESSAGE_OWNER_CAN_NOT_BE_ZERO        = 103;
    uint constant ERROR_NOT_ENOUGH_BALANCE                   = 201;
    uint constant ERROR_MEDIA_IS_SEALED                      = 202;
    uint constant ERROR_MEDIA_IS_NOT_SEALED                  = 203;
    uint constant ERROR_PART_OUT_OF_RANGE                    = 204;

    //========================================
    // Variables
    nftInfo  _info;  //
    nftMedia _media; //

    //========================================
    // Modifiers
    function _reserve() internal inline view {    tvm.rawReserve(gasToValue(100000, 0), 0);    }

    modifier onlyOwner   {    require(msg.sender.isStdAddrWithoutAnyCast() && _info.ownerAddress == msg.sender && _info.ownerAddress != addressZero, ERROR_MESSAGE_SENDER_IS_NOT_MY_OWNER);    _;    }
    modifier isSealed    {    require(_media.isSealed == true,  ERROR_MEDIA_IS_NOT_SEALED);    _;    }
    modifier isNotSealed {    require(_media.isSealed == false, ERROR_MEDIA_IS_SEALED    );    _;    }
    modifier reserve     {   _reserve();                                                       _;    }

    //========================================
    // Getters
    function  getInfo()         external             view         returns (nftInfo)  {    return                      (_info );             }
    function callInfo()         external responsible view reserve returns (nftInfo)  {    return {value: 0, flag: 128}(_info );             }
    function  getMedia()        external             view         returns (nftMedia) {    return                      (_media);             }
    function callMedia()        external responsible view reserve returns (nftMedia) {    return {value: 0, flag: 128}(_media);             }
    function  getOwnerAddress() external             view         returns (address)  {    return                      (_info.ownerAddress); }
    function callOwnerAddress() external responsible view reserve returns (address)  {    return {value: 0, flag: 128}(_info.ownerAddress); }

    //========================================
    //
    function sealMedia(bytes extension, bytes name, bytes comment) external onlyOwner isNotSealed
    {
        _media.extension = extension;
        _media.name      = name;
        _media.comment   = comment;
        _media.isSealed  = true;
    }

    //========================================
    //
    function _populateInfo(address ownerAddress, uint32 dtCreated) internal
    {
        _info.ownerAddress = ownerAddress;
        _info.dtCreated    = dtCreated;
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
    function setMediaPart(uint256 partNum, uint256 partsTotal, bytes data) external onlyOwner isNotSealed
    {
        _reserve();
        _setMediaPart(partNum, partsTotal, data);

        // Return the change
        msg.sender.transfer(0, true, 128);
    }
}

//================================================================================
//
