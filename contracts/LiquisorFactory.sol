pragma ton-solidity >=0.44.0;
pragma AbiHeader time;
pragma AbiHeader pubkey;
pragma AbiHeader expire;

//================================================================================
//
import "../contracts/LiquidNFTCollection.sol";
import "../contracts/AuctionDnsRecord.sol";
import "../contracts/AuctionLiquidNFT.sol";

//================================================================================
//
contract LiquisorFactory
{
    //========================================
    // Constants
    address constant addressZero = address.makeAddrStd(0, 0);

    //========================================
    // Error codes
    uint constant ERROR_MESSAGE_SENDER_IS_NOT_MY_OWNER = 100;

    //========================================
    // Variables
    address static _ownerAddress;
    TvmCell        _collectionCode;
    TvmCell        _tokenCode;
    TvmCell        _auctionDnsCode;
    TvmCell        _auctionTokenCode;

    //========================================
    // Modifiers
    function _reserve() internal inline view {    tvm.rawReserve(gasToValue(100000, 0), 0);    }

    modifier onlyOwner   {    require(msg.sender.isStdAddrWithoutAnyCast() && _ownerAddress == msg.sender && _ownerAddress != addressZero, ERROR_MESSAGE_SENDER_IS_NOT_MY_OWNER);    _;    }
    modifier reserve     {    _reserve();    _;                                       }
    modifier returnChange{                   _; msg.sender.transfer(0, true, 128);    }

    //========================================
    //
    function setCollectionCode  (TvmCell code) external onlyOwner reserve returnChange {    _collectionCode   = code;    }
    function setTokenCode       (TvmCell code) external onlyOwner reserve returnChange {    _tokenCode        = code;    }
    function setAuctionDnsCode  (TvmCell code) external onlyOwner reserve returnChange {    _auctionDnsCode   = code;    }
    function setAuctionTokenCode(TvmCell code) external onlyOwner reserve returnChange {    _auctionTokenCode = code;    }

    //========================================
    //
    function calculateFutureNFTCollectionAddress(bytes collectionName, uint256 ownerPubkey) private inline view returns (address, TvmCell)
    {
        TvmCell stateInit = tvm.buildStateInit({
            contr: LiquidNFTCollection,
            varInit: {
                _collectionName: collectionName,
                _tokenCode:      _tokenCode
            },
            code:   _collectionCode,
            pubkey: ownerPubkey
        });

        return (address(tvm.hash(stateInit)), stateInit);
    }

    //========================================
    //
    function calculateFutureAuctionDnsAddress(address escrowAddress, 
                                              uint128 escrowPercent, 
                                              address sellerAddress, 
                                              address buyerAddress, 
                                              address assetAddress, 
                                              AUCTION_TYPE auctionType, 
                                              uint128 minBid, 
                                              uint128 minPriceStep, 
                                              uint128 buyNowPrice, 
                                              uint32 dtStart, 
                                              uint32 dtEnd) private inline view returns (address, TvmCell)
    {
        TvmCell stateInit = tvm.buildStateInit({
            contr: AuctionDnsRecord,
            varInit: {
                _escrowAddress: escrowAddress,
                _escrowPercent: escrowPercent,
                _sellerAddress: sellerAddress,
                _buyerAddress:  buyerAddress,
                _assetAddress:  assetAddress,
                _auctionType:   auctionType,
                _minBid:        minBid,
                _minPriceStep:  minPriceStep,
                _buyNowPrice:   buyNowPrice,
                _dtStart:       dtStart,
                _dtEnd:         dtEnd
            },
            code: _auctionDnsCode
        });

        return (address(tvm.hash(stateInit)), stateInit);
    }

    //========================================
    //
    function calculateFutureAuctionTokenAddress(address escrowAddress, 
                                                uint128 escrowPercent, 
                                                address sellerAddress, 
                                                address buyerAddress, 
                                                address assetAddress, 
                                                AUCTION_TYPE auctionType, 
                                                uint128 minBid, 
                                                uint128 minPriceStep, 
                                                uint128 buyNowPrice, 
                                                uint32 dtStart, 
                                                uint32 dtEnd) private inline view returns (address, TvmCell)
    {
        TvmCell stateInit = tvm.buildStateInit({
            contr: AuctionLiquidNFT,
            varInit: {
                _escrowAddress: escrowAddress,
                _escrowPercent: escrowPercent,
                _sellerAddress: sellerAddress,
                _buyerAddress:  buyerAddress,
                _assetAddress:  assetAddress,
                _auctionType:   auctionType,
                _minBid:        minBid,
                _minPriceStep:  minPriceStep,
                _buyNowPrice:   buyNowPrice,
                _dtStart:       dtStart,
                _dtEnd:         dtEnd
            },
            code: _auctionTokenCode
        });

        return (address(tvm.hash(stateInit)), stateInit);
    }

    //========================================
    // 
    constructor() public
    {
        tvm.accept();
        // Return the change
        _ownerAddress.transfer(0, true, 128);
    }

    //========================================
    // 
    function createNFTCollection(bytes collectionName, address ownerAddress, uint256 ownerPubkey, uint256 uploaderPubkey) external
    {
        // TODO: add require that code in TvmCell exists
        _reserve();

        ( , TvmCell stateInit) = calculateFutureNFTCollectionAddress(collectionName, ownerPubkey);
        new LiquidNFTCollection{value: 0, flag: 128, stateInit: stateInit}(ownerAddress, uploaderPubkey);
    }

    //========================================
    // 
    function createAuctionDnsRecord(address escrowAddress, 
                                    uint128 escrowPercent, 
                                    address sellerAddress, 
                                    address buyerAddress, 
                                    address assetAddress, 
                                    AUCTION_TYPE auctionType, 
                                    uint128 minBid, 
                                    uint128 minPriceStep, 
                                    uint128 buyNowPrice, 
                                    uint32 dtStart, 
                                    uint32 dtEnd) external
    {
        // TODO: add require that code in TvmCell exists
        _reserve();

        ( , TvmCell stateInit) = calculateFutureAuctionDnsAddress(escrowAddress, escrowPercent, sellerAddress, buyerAddress, assetAddress, auctionType, minBid, minPriceStep, buyNowPrice, dtStart, dtEnd);
        new AuctionDnsRecord{value: 0, flag: 128, stateInit: stateInit}();
    }

    //========================================
    // 
    function createAuctionLiquidNFT(address escrowAddress, 
                                    uint128 escrowPercent, 
                                    address sellerAddress, 
                                    address buyerAddress, 
                                    address assetAddress, 
                                    AUCTION_TYPE auctionType, 
                                    uint128 minBid, 
                                    uint128 minPriceStep, 
                                    uint128 buyNowPrice, 
                                    uint32 dtStart, 
                                    uint32 dtEnd) external
    {
        // TODO: add require that code in TvmCell exists
        _reserve();

        ( , TvmCell stateInit) = calculateFutureAuctionTokenAddress(escrowAddress, escrowPercent, sellerAddress, buyerAddress, assetAddress, auctionType, minBid, minPriceStep, buyNowPrice, dtStart, dtEnd);
        new AuctionLiquidNFT{value: 0, flag: 128, stateInit: stateInit}();
    }
}