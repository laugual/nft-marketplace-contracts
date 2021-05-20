#!/usr/bin/env python3

# ==============================================================================
#
import freeton_utils
from   freeton_utils import *

class LiquidNFTCollection(object):
    def __init__(self, tonClient: TonClient, collectionName: str, signer: Signer = None):
        self.SIGNER      = generateSigner() if signer is None else signer
        self.TONCLIENT   = tonClient
        self.ABI         = "../bin/LiquidNFTCollection.abi.json"
        self.TVC         = "../bin/LiquidNFTCollection.tvc"
        self.TVC_NFT     = "../bin/LiquidNFT.tvc"
        self.CODE        = getCodeFromTvc(self.TVC)
        self.CODE_NFT    = getCodeFromTvc(self.TVC_NFT)
        self.CONSTRUCTOR = {}
        self.INITDATA    = {"_collectionName":stringToHex(collectionName), "_tokenCode": self.CODE_NFT}
        self.PUBKEY      = self.SIGNER.keys.public
        self.ADDRESS     = getAddress(abiPath=self.ABI, tvcPath=self.TVC, signer=self.SIGNER, initialPubkey=self.PUBKEY, initialData=self.INITDATA)
        self.NAME        = collectionName
        self.NAME_HEX    = stringToHex(collectionName)

    def deploy(self, ownerAddress: str, uploaderPubkey: str):
        self.CONSTRUCTOR = {"ownerAddress":ownerAddress, "uploaderPubkey":uploaderPubkey}
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

    def sealMedia(self, msig: SetcodeMultisig, value: int, extension: str, name: str, comment: str):
        result = self._callFromMultisig(msig=msig, functionName="sealMedia", functionParams={"extension":stringToHex(extension), "name":stringToHex(name), "comment":stringToHex(comment)}, value=value, flags=1)
        return result

    def setMediaPart(self, msig: SetcodeMultisig, value: int, partNum: str, partsTotal: str, data: str):
        result = self._callFromMultisig(msig=msig, functionName="setMediaPart", functionParams={"partNum":partNum, "partsTotal":partsTotal, "data":data}, value=value, flags=1)
        return result

    def createEmptyNFT(self, msig: SetcodeMultisig, value: int, uploaderPubkey: str):
        result = self._callFromMultisig(msig=msig, functionName="createEmptyNFT", functionParams={"uploaderPubkey":uploaderPubkey}, value=value, flags=1)
        return result

    def getCollectionName(self):
        result = self._run(functionName="getCollectionName", functionParams={})
        return result

    def getTokenCode(self):
        result = self._run(functionName="getTokenCode", functionParams={})
        return result

    def getTokensIssued(self):
        result = self._run(functionName="getTokensIssued", functionParams={})
        return result

    def getOwnerAddress(self):
        result = self._run(functionName="getOwnerAddress", functionParams={})
        return result

# ==============================================================================
# 
