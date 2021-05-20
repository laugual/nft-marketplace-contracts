#!/usr/bin/env python3

# ==============================================================================
#
import freeton_utils
from   freeton_utils import *

class LiquidNFT(object):
    def __init__(self, tonClient: TonClient, collectionAddress: str, tokenID: int, signer: Signer = None):
        self.SIGNER      = generateSigner() if signer is None else signer
        self.TONCLIENT   = tonClient
        self.ABI         = "../bin/LiquidNFT.abi.json"
        self.TVC         = "../bin/LiquidNFT.tvc"
        self.CODE        = getCodeFromTvc(self.TVC)
        self.CONSTRUCTOR = {}
        self.INITDATA    = {"_collectionAddress":collectionAddress, "_tokenID":tokenID}
        self.PUBKEY      = ZERO_PUBKEY
        self.ADDRESS     = getAddressZeroPubkey(abiPath=self.ABI, tvcPath=self.TVC, initialData=self.INITDATA)

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

    def setMediaPart2(self, partNum: str, partsTotal: str, data: str):
        result = self._call(functionName="setMediaPart", functionParams={"partNum":partNum, "partsTotal":partsTotal, "data":data}, signer=self.SIGNER)
        return result

    def getInfo(self):
        result = self._run(functionName="getInfo", functionParams={})
        return result

    def getMedia(self):
        result = self._run(functionName="getMedia", functionParams={})
        return result

    def getOwnerAddress(self):
        result = self._run(functionName="getOwnerAddress", functionParams={})
        return result

# ==============================================================================
# 
