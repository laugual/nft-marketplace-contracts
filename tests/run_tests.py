#!/usr/bin/env python3

# ==============================================================================
# 
import freeton_utils
from   freeton_utils import *
import binascii
import unittest
import time
import sys
from   pathlib import Path
from   pprint import pprint
from   contract_LiquidNFT           import LiquidNFT
from   contract_LiquidNFTCollection import LiquidNFTCollection

TON = 1000000000
SERVER_ADDRESS = "https://net.ton.dev"

# ==============================================================================
#
def getClient():
    return TonClient(config=ClientConfig(network=NetworkConfig(server_address=SERVER_ADDRESS)))

# ==============================================================================
# 
# Parse arguments and then clear them because UnitTest will @#$~!
for _, arg in enumerate(sys.argv[1:]):
    if arg == "--disable-giver":
        
        freeton_utils.USE_GIVER = False
        sys.argv.remove(arg)

    if arg == "--throw":
        
        freeton_utils.THROW = True
        sys.argv.remove(arg)

    if arg.startswith("http"):
        
        SERVER_ADDRESS = arg
        sys.argv.remove(arg)

    if arg.startswith("--msig-giver"):
        
        freeton_utils.MSIG_GIVER = arg[13:]
        sys.argv.remove(arg)

# ==============================================================================
# EXIT CODE FOR SINGLE-MESSAGE OPERATIONS
# we know we have only 1 internal message, that's why this wrapper has no filters
def _getAbiArray():
    return ["../bin/LiquidNFT.abi.json", "../bin/LiquidNFTCollection.abi.json", "../bin/SetcodeMultisigWallet.abi.json"]

def _getExitCode(msgIdArray):
    abiArray     = _getAbiArray()
    msgArray     = unwrapMessages(getClient(), msgIdArray, abiArray)
    if msgArray != "":
        realExitCode = msgArray[0]["TX_DETAILS"]["compute"]["exit_code"]
    else:
        realExitCode = -1
    return realExitCode   

def readBinaryFile(fileName):
    with open(fileName, 'rb') as f:
        contents = f.read()
    #return(binascii.hexlify(contents).hex(), Path(fileName).stem, Path(fileName).suffix)
    return(contents.hex(), Path(fileName).stem, Path(fileName).suffix)

def chunkstring(string, length):
    return list(string[0+i:length+i] for i in range(0, len(string), length))

# ==============================================================================
# 
class Test_01_DeployCollection(unittest.TestCase):

    msig       = SetcodeMultisig(tonClient=getClient())
    collection = LiquidNFTCollection(tonClient=getClient(), collectionName="mycol")
    token1     = LiquidNFT(tonClient=getClient(), collectionAddress=collection.ADDRESS, tokenID=0)
    
    def test_0(self):
        print("\n\n----------------------------------------------------------------------")
        print("Running:", self.__class__.__name__)

    # 1. Giver
    def test_1(self):
        giverGive(getClient(), self.msig.ADDRESS,       TON * 10)
        giverGive(getClient(), self.collection.ADDRESS, TON * 1)

    # 2. Deploy multisig
    def test_2(self):
        result = self.msig.deploy()
        self.assertEqual(result[1]["errorCode"], 0)

    # 3. Deploy collection
    def test_3(self):
        result = self.collection.deploy(ownerAddress=self.msig.ADDRESS, uploaderPubkey="0x00")
        self.assertEqual(result[1]["errorCode"], 0)

    # 4. Get info
    def test_4(self):
        # Collection cover is empty-garbage
        self.collection.sealMedia(msig=self.msig, value=100000000, extension="kek", name="kek-name", comment="kek-comment")
        
        # LOB
        #media, name, ext = readBinaryFile("./image_chain.png")
        media, name, ext = readBinaryFile("./image_262kb.png")
        chunks = chunkstring(media, 30000)
        num = len(chunks)

        # 1. 
        result = self.collection.createEmptyNFT(msig=self.msig, value=500000000, uploaderPubkey="0x" + self.token1.SIGNER.keys.public)

        # For external uploader only
        giverGive(getClient(), self.token1.ADDRESS, TON * 5)

        # 2.
        print("")
        for i in range(0, num):
            progress = (i/(num-1))
            print("\rUploading media: [{0:50s}] {1:.1f}%".format('#' * int(progress * 50), progress*100), end="", flush=True)
            #result = self.token1.setMediaPart(msig=self.msig, value=100000000, partNum=i, partsTotal=num, data=chunks[i])
            result = self.token1.setMediaPartExternal(partNum=i, partsTotal=num, data=chunks[i])
        print("")
            
        # 3.
        self.token1.sealMedia(msig=self.msig, value=100000000, extension=ext, name=name, comment="put it on your hand you punk")

        result = self.token1.getMedia()
        self.assertEqual("".join(result["contents"]), media)
        self.assertEqual(result["extension"],         stringToHex(ext))
        self.assertEqual(result["name"],              stringToHex(name))

    # 5. Cleanup
    def test_5(self):
        result = self.msig.destroy(addressDest = freeton_utils.giverGetAddress())
        self.assertEqual(result[1]["errorCode"], 0)

# ==============================================================================
# 
unittest.main()
