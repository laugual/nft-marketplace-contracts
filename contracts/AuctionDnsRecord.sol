pragma ton-solidity >=0.43.0;
pragma AbiHeader time;
pragma AbiHeader pubkey;
pragma AbiHeader expire;

//================================================================================
//
import "../interfaces/IDnsRecord.sol";
import "../interfaces/ILiquisorAuction.sol";

//================================================================================
//
contract AuctionDnsRecord is ILiquisorAuction
{
    //========================================
    //
    function transferAsset(address receiver) internal override
    {
        if(_assetTransferred) { return; }
        IDnsRecord(_assetAddress).changeOwner{value: 0, bounce: true, flag: 128}(receiver);
    }
    
    //========================================
    //
    function checkAssetTransferred() internal override
    {
        _reserve();
        IDnsRecord(_assetAddress).callWhois{value: 0, callback: callbackOnCheckAssetTransferred, flag: 128}();
    }
    
    //========================================
    //
    function callbackOnCheckAssetTransferred(DnsWhois whois) public onlyAsset
    {
        _reserve();
        address desiredOwner = (_currentBuyer      == addressZero ? _sellerAddress : _currentBuyer);
        _assetTransferred    = (whois.ownerAddress == desiredOwner);
        _sellerAddress.transfer(0, true, 128);
    }

    //========================================
    //
    function receiveAsset() public override onlySeller
    {
        _reserve();
        IDnsRecord(_assetAddress).callWhois{value: 0, callback: callbackOnReceiveAsset, flag: 128}();
    }
    
    //========================================
    //
    function callbackOnReceiveAsset(DnsWhois whois) public onlyAsset
    {
        _reserve();
        _assetReceived  = (whois.ownerAddress == address(this));
        _auctionStarted = (whois.ownerAddress == address(this));
        _sellerAddress.transfer(0, true, 128);
    }
}

//================================================================================
//
