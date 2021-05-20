pragma ton-solidity >=0.44.0;
pragma AbiHeader time;
pragma AbiHeader pubkey;
pragma AbiHeader expire;

//================================================================================
//
enum AUCTION_TYPE
{
    OPEN_AUCTION, //
    PUBLIC_BUY,   //
    PRIVATE_BUY,  //
    NUM           //
}

//================================================================================
//
abstract contract ILiquisorAuction
{
    //========================================
    // Constants
    address constant addressZero = address.makeAddrStd(0, 0);

    //========================================
    // Error codes
    uint constant ERROR_MESSAGE_SENDER_IS_NOT_MY_OWNER = 100;
    uint constant ERROR_AUCTION_NOT_RUNNING            = 200;
    uint constant ERROR_AUCTION_ENDED                  = 201;
    uint constant ERROR_ASSET_NOT_TRANSFERRED          = 202;
    uint constant ERROR_AUCTION_IN_PROCESS             = 203;
    uint constant ERROR_NOT_ENOUGH_MONEY               = 204;
    uint constant ERROR_DO_NOT_BEAT_YOURSELF           = 205;
    uint constant ERROR_MESSAGE_SENDER_IS_NOT_SELLER   = 206;
    uint constant ERROR_MESSAGE_SENDER_IS_NOT_ASSET    = 207;
    uint constant ERROR_INVALID_AUCTION_TYPE           = 208;
    uint constant ERROR_INVALID_BUYER_ADDRESS          = 209;

    //========================================
    // Variables
    address      static _escrowAddress; // escrow multisig for collecting fees;
    uint128      static _escrowPercent; // times 100; 1% = 100, 10% = 1000;
    address      static _sellerAddress; // seller is the real asset owner;
    address      static _buyerAddress;  // buyer is specified only when "_type" is AUCTION_TYPE.CLOSE_BUY, otherwise 0:0000000000000000000000000000000000000000000000000000000000000000;
    address      static _assetAddress;  // asset contract address;
    AUCTION_TYPE static _auctionType;   //
    uint128      static _minBid;        //
    uint128      static _minPriceStep;  //
    uint128      static _buyNowPrice;   //
    uint32       static _dtStart;       //
    uint32       static _dtEnd;         //

    bool         _assetReceived;        //
    bool         _auctionStarted;       //
    bool         _auctionSucceeded;     //
    bool         _moneySentOut;         //
    bool         _assetTransferred;     //
    address      _currentBuyer;         //
    uint128      _currentBuyPrice;      //

    //========================================
    // Modifiers
    function _reserve() internal inline view {    tvm.rawReserve(gasToValue(100000, 0), 0);    }
    modifier  onlySeller {    require(_sellerAddress != addressZero && _sellerAddress == msg.sender, ERROR_MESSAGE_SENDER_IS_NOT_SELLER);    _; }
    modifier  onlyAsset  {    require(_assetAddress  != addressZero && _assetAddress  == msg.sender, ERROR_MESSAGE_SENDER_IS_NOT_ASSET );    _; }
    modifier  reserve    {   _reserve();    _;    }

    //========================================
    //
    constructor() public
    {
        tvm.accept();

        _assetReceived    = false;
        _auctionStarted   = false; // Start only after we are sure that asset is transfered to auction contract;
        _auctionSucceeded = false; // Finish after time is out or when the public/private buy is done;
        _moneySentOut     = false; // Called when finalize is first called;
        _assetTransferred = false;
        _currentBuyer     = addressZero;
        _currentBuyPrice  = 0;
    }

    //========================================
    // Place a new bid
    function bid() external
    {
        require(_auctionType < AUCTION_TYPE.NUM, ERROR_INVALID_AUCTION_TYPE );
        if(_auctionType != AUCTION_TYPE.OPEN_AUCTION)
        {
            require(msg.sender == _buyerAddress && _buyerAddress != addressZero, ERROR_INVALID_BUYER_ADDRESS);
        }

        uint128 desiredPrice = 0;
             if(_auctionType == AUCTION_TYPE.OPEN_AUCTION) {    desiredPrice = (_currentBuyPrice == 0 ? _minBid :  _currentBuyPrice + _minPriceStep);    }
        else if(_auctionType == AUCTION_TYPE.PUBLIC_BUY)   {    desiredPrice = _buyNowPrice;                                                             }
        else if(_auctionType == AUCTION_TYPE.PRIVATE_BUY)  {    desiredPrice = _buyNowPrice;                                                             }

        require(now >= _dtStart && now <= _dtEnd, ERROR_AUCTION_NOT_RUNNING  );
        require( _auctionStarted,                 ERROR_AUCTION_NOT_RUNNING  );
        require(!_auctionSucceeded,               ERROR_AUCTION_ENDED        );
        require(msg.sender != _currentBuyer,      ERROR_DO_NOT_BEAT_YOURSELF );
        require(msg.value  >= desiredPrice,       ERROR_NOT_ENOUGH_MONEY     );

        _reserve(); // reserve minimum balance;

        if(_auctionType == AUCTION_TYPE.OPEN_AUCTION)
        {
            // TODO: if it's the first buyer than there will be an error, because reserve will get everything below 0
            tvm.rawReserve(msg.value, 0); // reserve new buyer's amount; previous buyer pays the fees;
            if(_currentBuyer != addressZero)
            {
                _currentBuyer.transfer(0, true, 128); // return TONs to previous buyer (excluding fees);
            }
        }
        else
        {
            tvm.rawReserve(_buyNowPrice, 0); // reserve buy price, we don't want the change;
            _auctionSucceeded = true;
        }

        // Update current buyer
        _currentBuyer    = msg.sender;
        _currentBuyPrice = msg.value;
    }
    
    //========================================
    //
    function _sendOutTheMoney() internal
    {
        if(_moneySentOut) { return; }

        // Calculate escrow fees;
        uint128 escrowFees = _currentBuyPrice / 10000 * _escrowPercent;
        uint128 finalPrice = _currentBuyPrice - escrowFees;

        // Send out the money;
        _sellerAddress.transfer(finalPrice, true, 0);
        _escrowAddress.transfer(escrowFees, true, 1);

        _moneySentOut = true;
    }

    //========================================
    /// @dev you can call "finalize" as many times as you want;
    //
    function finalize() external
    {
        require(now > _dtEnd || _auctionSucceeded, ERROR_AUCTION_IN_PROCESS);
        
        // No asset was ever received, 
        if(!_assetReceived) { return; }

        // No bids were made, return asset to the owner and all the money to escrow;
        if(_auctionType == AUCTION_TYPE.OPEN_AUCTION && _currentBuyer == addressZero)
        {
            transferAsset(_sellerAddress);
            checkAssetTransferred(); // Ensure that seller got the asset back
            return;
        }
        else
        {
            if(!_auctionSucceeded)
            {
                transferAsset(_sellerAddress);
                checkAssetTransferred(); // Ensure that seller got the asset back
                return;
            }
        }

        _sendOutTheMoney();

        // Transfer asset to a new owner;
        // TODO: selfdestruct only after successfull asset transfer?;
        transferAsset(_currentBuyer);
        checkAssetTransferred(); // Ensure that buyer got the asset back
    }

    //========================================
    //
    /*function destroy() external onlySeller
    {

    }*/

    //========================================
    //
    onBounce(TvmSlice slice) external pure
    {
		uint32 func = slice.decode(uint32);
		if(func == tvm.functionId(receiveAsset)) 
        {
            // TODO: failed to register asset
        }
    }

    //========================================
    // Called ONLY after auction is finished;
    function transferAsset(address receiver) internal virtual;

    //========================================
    // Called ONLY after auction is finished;
    function checkAssetTransferred() internal virtual;
    
    //========================================
    // Called BEFORE auction is started;
    // That means we don't have any bids yet, only minimal balance;
    function receiveAsset() public virtual;
}

//================================================================================
//
