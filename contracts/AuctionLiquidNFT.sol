pragma ton-solidity >=0.43.0;
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
    function transferAsset(address receiver) internal override
    {
        if(_assetTransferred) { return; }
        LiquidNFT(_assetAddress).changeOwner{value: 0, bounce: true, flag: 128}(receiver);
    }
    
    //========================================
    //
    function checkAssetTransferred() internal override
    {
        _reserve();
        LiquidNFT(_assetAddress).callOwnerAddress{value: 0, callback: callbackOnCheckAssetTransferred, flag: 128}();
    }
    
    //========================================
    //
    function callbackOnCheckAssetTransferred(address ownerAddress) public onlyAsset
    {
        _reserve();
        address desiredOwner = (_currentBuyer == addressZero ? _sellerAddress : _currentBuyer);
        _assetTransferred    = ( ownerAddress == desiredOwner);
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