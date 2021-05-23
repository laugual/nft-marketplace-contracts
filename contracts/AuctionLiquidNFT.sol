pragma ton-solidity >=0.44.0;
pragma AbiHeader time;
pragma AbiHeader pubkey;
pragma AbiHeader expire;

//================================================================================
//
import "../contracts/LiquidNFT.sol";
import "../interfaces/ILiquisorAuction.sol";

//================================================================================
//
contract AuctionLiquidNFT is ILiquisorAuction
{
    //========================================
    //
    constructor() public
    {
        _init();
    }

    //========================================
    //
    function deliverAsset(address receiver) internal override
    {
        if(_assetDelivered) { return; }
        LiquidNFT(_assetAddress).changeOwner{value: 0.1 ton, bounce: true, flag: 1}(receiver);
    }
    
    //========================================
    //
    function checkAssetDelivered() internal override
    {
        _reserve();
        LiquidNFT(_assetAddress).callOwnerAddress{value: 0, callback: callbackOnCheckAssetDelivered, flag: 128}();
    }
    
    //========================================
    //
    function callbackOnCheckAssetDelivered(address ownerAddress) public onlyAsset
    {
        _reserve();
        address desiredOwner = (_currentBuyer == addressZero ? _sellerAddress : _currentBuyer);
        _assetDelivered      = ( ownerAddress == desiredOwner);
        _sellerAddress.transfer(0, true, 128);
    }

    //========================================
    //
    function receiveAsset() public override onlySeller
    {
        _reserve();
        LiquidNFT(_assetAddress).callOwnerAddress{value: 0, callback: callbackOnReceiveAsset, flag: 128}();
    }
    
    //========================================
    //
    function callbackOnReceiveAsset(address ownerAddress) public onlyAsset
    {
        _reserve();
        _assetReceived  = (ownerAddress == address(this));
        _auctionStarted = (ownerAddress == address(this));
        _sellerAddress.transfer(0, true, 128);
    }
}

//================================================================================
//