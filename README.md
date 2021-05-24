# LiquiSOR NFT Marketplace

## Summary

Contracts, artifacts and tests for LiquiSOR NFT Marketplace.

## Entities

* `Dns Record` - DeNS contract from https://github.com/laugual/dens-v2. Can be traded on the marketplace.

* `NFT Collection` - Token collection. Current approach follows "no-token-wallet" idea.

The idea behind Collections is that a person can _(and should)_ have multiple collections that group NFTs logically. Logical grouping implies keeping `Flower NFTs` in one collection, `Coin NFTs` in the other, `Pokemon NFTs` in third, etc.

Collection also has media _(like NFT does)_ and is used to keep Collection cover and description.

* `Token` - Original TIP-3 NFTs suggested having a wallet that keeps the list of IDs, and each ID represents an NFT. This approach limits the freedom of NFT creation as NFTs are `faceless` IDs that mean nothing without target media.

Our approach extends NFTs to be `Token = Contract`, each NFT is a separate contract that holds arbitrary attributes and has the owner.

* `Factory` - Factory is a helper contract that can create NFT Collections and auctions.

* `Auction` - Auction contract that acts like escrow to run secure deals between two people. An asset is locked during auction time and is released only after money is received or auction period is over.

## Contracts 

### Common functions for `LiquidNFTCollection.sol` and `LiquidNFT.sol`

#### getInfo

Returns the NFT information using the following structure:

``` js
struct nftInfo
{
    uint32  dtCreated;
    address ownerAddress;
    address authorAddress;
}
```

`dtCreated` - NFT creation date in UNIX time.

`ownerAddress` - Address of the current NFT owner. Can only be another contract's address (Multisig is preferred), can't be external (e.g. Public Key).

`authorAddress` - Address of the NFT creator, can't be changed.


``` js
function getInfo() external view returns (nftInfo)
function callInfo() external responsible view returns (nftInfo)
```

#### getMedia

Returns the NFT media data using the following structure:

``` js
struct nftMedia
{
    bytes[] contents;
    bytes   extension;
    bytes   name;
    bytes   comment;
    bool    isSealed;
}
```

`contents` - NFT contents. Either binary file _(every array item represents a chunk in binary hex)_, or arbitrary link/hash to NFT media.

`extension` - Type of the contents: extension for binary files _(e.g. `gif`, `png`, `mp4` etc.)_ or type for the link/hash _(e.g. `#url`, `#hash`, `#address` etc.)_.

`name` - Name of the token, e.g. `Mona Lisa`.

`comment` - Arbitrtary comment of the token.

`isSealed` - Sealing means finalizing token contents. Sealed token can't be changed anymore. Sealed token can be transfered to another owner.


``` js
function getMedia() external view returns (nftMedia)
function callMedia() external responsible view returns (nftMedia)
```


#### getOwnerAddress

Returns current owner address.

``` js
function getOwnerAddress() external view returns (address)
function callOwnerAddress() external responsible view returns (address)
```

#### changeOwner

Transfers ownership of the NFT to `newOwnerAddress`. NFT needs to have attribute `isSealed` to perform the transfer.

ACCESS: Owner; Sealed.

``` js
function changeOwner(address newOwnerAddress)
function callChangeOwner(address newOwnerAddress) external responsible returns (address)
```

#### setMediaPart

Uploads `data` into `partNum` array index of total `partsTotal` array length.

`setMediaPartExternal` is used to directly upload data without multisig _(transferring TONs to NFT account is rewquired, because `tvm.accept()` is used)_. 

REASONING: Forward fees for 1 Kb of data cost 0.01 TON, when uploading via multisig you pay double fees _(first is external message to multisig; second - message from multisig to NFT)_. Direct upload allows you to pay only for one forward fee.

ACCESS: Owner _(or Pubkey if set)_; Not Sealed.

``` js
function setMediaPart(uint256 partNum, uint256 partsTotal, bytes data)
function setMediaPartExternal(uint256 partNum, uint256 partsTotal, bytes data)
```

#### sealMedia

Seals the media, populating media `extenstion`, `name` and `comment`. `name` and `comment` are arbitrary. Also removes `uploaderPubkey`.

ACCESS: Owner; Not Sealed.

``` js
function sealMedia(bytes extension, bytes name, bytes comment)
```

#### touch

Owner can touch his NFTs (One of the ways to pay storage fees for the contract).

ACCESS: Owner.

``` js
function touch()
```

### Unique contract functions for `LiquisorFactory.sol`

#### constructor

Creates a new Collection with `ownerAddress` and optional `uploaderPubkey` to upload the cover. This Pubkey can be used to directly update media inside Collection _(while not yet Sealed)_.

``` js
constructor(address ownerAddress, uint256 uploaderPubkey)
```

#### createEmptyNFT

Creates an empty NFT with optional `uploaderPubkey`. This Pubkey can be used to directly update media inside NFT _(while not yet Sealed)_.

``` js
function createEmptyNFT(uint256 uploaderPubkey)
```

### Unique contract functions for `LiquidNFT.sol`

#### constructor

Creates a new NFT with `ownerAddress` and optional `uploaderPubkey` to upload media. This Pubkey can be used to directly update media inside NFT _(while not yet Sealed)_.

ACCESS: Collection contract only.

``` js
constructor(address ownerAddress, uint256 uploaderPubkey)
```

### Unique contract functions for `LiquisorFactory.sol`

#### createNFTCollection

Creates a new Collection with `collectionName`, `ownerAddress`, optional `ownerPubkey` and optional `uploaderPubkey` to upload the cover. This Pubkey can be used to directly update media inside Collection _(while not yet Sealed)_.

``` js
function createNFTCollection(bytes collectionName, address ownerAddress, uint256 ownerPubkey, uint256 uploaderPubkey)
```

#### createAuctionDnsRecord

Creates a new Auction to sell DnsRecord contract.

LIMITATIONS: Yo can't create an auction with duration more than 14 days, we don't want your asset to be locked for years.

``` js
function createAuctionDnsRecord(address      escrowAddress, 
                                uint128      escrowPercent, 
                                address      sellerAddress, 
                                address      buyerAddress, 
                                address      assetAddress, 
                                AUCTION_TYPE auctionType, 
                                uint128      minBid, 
                                uint128      minPriceStep, 
                                uint128      buyNowPrice, 
                                uint32       dtStart, 
                                uint32       dtEnd) 
```

#### createAuctionLiquidNFT

Creates a new Auction to sell LiquidNFT contract.

LIMITATIONS: Yo can't create an auction with duration more than 14 days, we don't want your asset to be locked for years.

``` js
function createAuctionLiquidNFT(address      escrowAddress, 
                                uint128      escrowPercent, 
                                address      sellerAddress, 
                                address      buyerAddress, 
                                address      assetAddress, 
                                AUCTION_TYPE auctionType, 
                                uint128      minBid, 
                                uint128      minPriceStep, 
                                uint128      buyNowPrice, 
                                uint32       dtStart, 
                                uint32       dtEnd)
```

### Unique contract functions for `AuctionLiquidNFT.sol` and `AuctionDnsRecord.sol`

#### AUCTION_TYPE

* `OPEN_AUCTION` - Anyone can participate, `Buy Now` price is optional. Higher bets cancel previous bets.

* `PUBLIC_BUY` - Anyone can participate, but there is no bid war, only `Buy Now` price is set. First buyer gets an asset.

* `PRIVATE_BUY` - Private sale with only `Buy Now` price set. Secure way to sell an asset to desired buyer.

#### receiveAsset

Auction checks that he is the owner of the asset. In order to start an Auction asset's `ownerAddress` should be changed to Auction address. It excludes any frauds and scam actions that asset owner can try to plot.

If the asset is transferred, calling this function will start the Auction automatically.

PLEASE BE SURE TO TRANSFER YOUR ASSET ONLY TO VALID AUCTIONS!

ACCESS: Seller only _(and only before auction starts)_.

``` js
function receiveAsset()
```

#### bid

Place a bid. All incoming value _(excluding 0.5 TON to cover the fees, the change will be returned to the sender)_ is considered as a bet value. Money are held until someone beats you bet or until Auction is over.

``` js
function bid()
```

#### cancelAuction

Cancels current auction.

ACCESS: Seller only _(and only while there are no active bets)_.

``` js
function cancelAuction()
```

#### finalize

Finalizes auction results when auction is over. If there is a buyer, he gets an asset and seller gets the money. If there is no buyer, seller gets an asset back.


``` js
function finalize()
```
