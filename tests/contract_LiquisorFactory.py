#!/usr/bin/env python3

# ==============================================================================
#
import freeton_utils
from   freeton_utils import *

class LiquisorFactory(object):
    def __init__(self, tonClient: TonClient, ownerAddress: str, signer: Signer = None):
        self.SIGNER      = generateSigner() if signer is None else signer
        self.TONCLIENT   = tonClient
        self.ABI         = "../bin/LiquisorFactory.abi.json"
        self.TVC         = "../bin/LiquisorFactory.tvc"
        self.CODE        = getCodeFromTvc(self.TVC)
        self.CONSTRUCTOR = {}
        self.INITDATA    = {"_ownerAddress":ownerAddress}
        self.PUBKEY      = ZERO_PUBKEY
        self.ADDRESS     = getAddress(abiPath=self.ABI, tvcPath=self.TVC, signer=self.SIGNER, initialPubkey=self.PUBKEY, initialData=self.INITDATA)

    def deploy(self):
        result = deployContract(tonClient=self.TONCLIENT, abiPath=self.ABI, tvcPath=self.TVC, constructorInput=self.CONSTRUCTOR, initialData=self.INITDATA, signer=self.SIGNER, initialPubkey=self.PUBKEY)
        return result

    def _call(self, functionName, functionParams, signer):
        result = callFunction(tonClient=self.TONCLIENT, abiPath=self.ABI, contractAddress=self.ADDRESS, functionName=functionName, functionParams=functionParams, signer=signer)
        return result

    def _callFromMultisig(self, msig: SetcodeMultisig, functionName, functionParams, value, flags):
        messageBoc = prepareMessageBoc(abiPath=self.ABI, functionName=functionName, functionParams=functionParams)
        result     = msig.callTransfer(addressDest=self.ADDRESS, value=value, payload=messageBoc, flags=flags)
        return result

    def _run(self, functionName, functionParams):
        result = runFunction(tonClient=self.TONCLIENT, abiPath=self.ABI, contractAddress=self.ADDRESS, functionName=functionName, functionParams=functionParams)
        return result

    # ========================================
    #
    def setCollectionCode(self, msig: SetcodeMultisig, value: int, code: str):
        result = self._callFromMultisig(msig=msig, functionName="setCollectionCode", functionParams={"code":code}, value=value, flags=1)
        return result

    def setTokenCode(self, msig: SetcodeMultisig, value: int, code: str):
        result = self._callFromMultisig(msig=msig, functionName="setTokenCode", functionParams={"code":code}, value=value, flags=1)
        return result

    def setAuctionDnsCode(self, msig: SetcodeMultisig, value: int, code: str):
        result = self._callFromMultisig(msig=msig, functionName="setAuctionDnsCode", functionParams={"code":code}, value=value, flags=1)
        return result

    def setAuctionTokenCode(self, msig: SetcodeMultisig, value: int, code: str):
        result = self._callFromMultisig(msig=msig, functionName="setAuctionTokenCode", functionParams={"code":code}, value=value, flags=1)
        return result

    # ========================================
    #
    def createNFTCollection(self, msig: SetcodeMultisig, value: int, collectionName: str, ownerAddress: str, ownerPubkey: str, uploaderPubkey: str):
        result = self._callFromMultisig(msig=msig, functionName="createNFTCollection", functionParams={"collectionName":stringToHex(collectionName), "ownerAddress":ownerAddress, "ownerPubkey":ownerPubkey, "uploaderPubkey":uploaderPubkey}, value=value, flags=1)
        return result

    def createAuctionDnsRecord(self, msig: SetcodeMultisig, value: int, escrowAddress: str, escrowPercent: int, sellerAddress: str, buyerAddress: str, assetAddress: str, auctionType: int, minBid: int, minPriceStep: int, buyNowPrice: int, dtStart: int, dtEnd: int):
        result = self._callFromMultisig(msig=msig, functionName="createAuctionDnsRecord", functionParams={
            "escrowAddress":escrowAddress, "escrowPercent":escrowPercent, "sellerAddress":sellerAddress, 
            "buyerAddress":buyerAddress,   "assetAddress":assetAddress,   "auctionType":auctionType, 
            "minBid":minBid,               "minPriceStep":minPriceStep,   "buyNowPrice":buyNowPrice, 
            "dtStart":dtStart,             "dtEnd":dtEnd}, value=value, flags=1)
        return result

# ==============================================================================
# 
