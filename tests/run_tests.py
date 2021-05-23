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
from   contract_LiquisorFactory     import LiquisorFactory
from   contract_AuctionDnsRecord    import AuctionDnsRecord
from   contract_DnsRecordTEST       import DnsRecordTEST

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
    return ["../bin/LiquidNFT.abi.json", "../bin/LiquidNFTCollection.abi.json", "../bin/LiquisorFactory.abi.json", "../bin/AuctionDnsRecord.abi.json", "../bin/SetcodeMultisigWallet.abi.json"]

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
class Test_02_DeployCollectionFromFactory(unittest.TestCase):

    msig       = SetcodeMultisig(tonClient=getClient())
    factory    = LiquisorFactory(tonClient=getClient(), ownerAddress=msig.ADDRESS)
    collection = LiquidNFTCollection(tonClient=getClient(), collectionName="mycol", signer=msig.SIGNER)
    
    def test_0(self):
        print("\n\n----------------------------------------------------------------------")
        print("Running:", self.__class__.__name__)

    # 1. Giver
    def test_1(self):
        giverGive(getClient(), self.msig.ADDRESS,    TON * 10)
        giverGive(getClient(), self.factory.ADDRESS, TON * 1)

        print(self.collection.ADDRESS)

    # 2. Deploy multisig
    def test_2(self):
        result = self.msig.deploy()
        self.assertEqual(result[1]["errorCode"], 0)

    # 3. Deploy factory
    def test_3(self):
        result = self.factory.deploy()
        self.assertEqual(result[1]["errorCode"], 0)

    # 4. Get info
    def test_4(self):
        self.factory.setCollectionCode(msig=self.msig, value=TON, code=self.collection.CODE    )
        self.factory.setTokenCode     (msig=self.msig, value=TON, code=self.collection.CODE_NFT)

        result = self.factory.createNFTCollection(msig=self.msig, value=TON, collectionName="mycol", ownerAddress=self.msig.ADDRESS, ownerPubkey="0x"+self.msig.SIGNER.keys.public, uploaderPubkey="0x00")
        self.assertEqual(result[1]["errorCode"], 0)

        #msgArray = unwrapMessages(getClient(), result[0].transaction["out_msgs"], _getAbiArray())
        #pprint(msgArray)

        self.collection.sealMedia(msig=self.msig, value=100000000, extension="kek", name="kek-name", comment="kek-comment")

        result = self.collection.getMedia()
        print(result)

    # 5. Cleanup
    def test_5(self):
        result = self.msig.destroy(addressDest = freeton_utils.giverGetAddress())
        self.assertEqual(result[1]["errorCode"], 0)

# ==============================================================================
# 
class Test_03_DeployDnsAuction(unittest.TestCase):

    msig    = SetcodeMultisig(tonClient=getClient())
    msig2   = SetcodeMultisig(tonClient=getClient())
    factory = LiquisorFactory(tonClient=getClient(), ownerAddress=msig.ADDRESS)
    domain  = DnsRecordTEST(tonClient=getClient(), name="kek")
    dtNow   = getNowTimestamp()
    
    auction = AuctionDnsRecord(
        tonClient     = getClient(), 
        escrowAddress = msig.ADDRESS, 
        escrowPercent = 500, 
        sellerAddress = msig.ADDRESS, 
        buyerAddress  = msig2.ADDRESS, 
        assetAddress  = domain.ADDRESS, 
        auctionType   = 2, # PRIVATE_BUY 
        minBid        = TON, 
        minPriceStep  = TON, 
        buyNowPrice   = TON*6, 
        dtStart       = dtNow+1, 
        dtEnd         = dtNow+70)
    
    def test_0(self):
        print("\n\n----------------------------------------------------------------------")
        print("Running:", self.__class__.__name__)

    # 1. Giver
    def test_1(self):
        giverGive(getClient(), self.msig.ADDRESS,    TON * 10)
        giverGive(getClient(), self.msig2.ADDRESS,   TON * 20)
        giverGive(getClient(), self.factory.ADDRESS, TON * 1)
        giverGive(getClient(), self.domain.ADDRESS,  TON * 1)
        giverGive(getClient(), self.auction.ADDRESS, TON * 1)

        #print(self.auction.ADDRESS)

    # 2. Deploy multisig
    def test_2(self):
        result = self.msig.deploy()
        self.assertEqual(result[1]["errorCode"], 0)
        result = self.msig2.deploy()
        self.assertEqual(result[1]["errorCode"], 0)
        result = self.domain.deploy(ownerAddress=self.msig.ADDRESS)
        self.assertEqual(result[1]["errorCode"], 0)

    # 3. Deploy something else
    def test_3(self):
        result = self.factory.deploy()
        self.assertEqual(result[1]["errorCode"], 0)
        
    # 4. Get info
    def test_4(self):
        self.factory.setAuctionDnsCode(msig=self.msig, value=TON, code=self.auction.CODE)

        result = self.factory.createAuctionDnsRecord(msig=self.msig, value=TON, 
            escrowAddress = self.msig.ADDRESS, 
            escrowPercent = 500, 
            sellerAddress = self.msig.ADDRESS, 
            buyerAddress  = self.msig2.ADDRESS, 
            assetAddress  = self.domain.ADDRESS, 
            auctionType   = 2, # PRIVATE_BUY 
            minBid        = TON, 
            minPriceStep  = TON, 
            buyNowPrice   = TON*6, 
            dtStart       = self.dtNow+1, 
            dtEnd         = self.dtNow+70)
        
        result = self.domain.callFromMultisig(msig=self.msig, functionName="changeOwner", functionParams={"newOwnerAddress": self.auction.ADDRESS}, value=100000000, flags=1)

        result = self.auction.receiveAsset(msig=self.msig, value=100000000)
        msgArray = unwrapMessages(getClient(), result[0].transaction["out_msgs"], _getAbiArray())

        result = self.auction.bid(msig=self.msig2, value=TON*7)
        msgArray = unwrapMessages(getClient(), result[0].transaction["out_msgs"], _getAbiArray())
        #pprint(msgArray)

        result = self.auction.finalize(msig=self.msig2, value=TON)
        msgArray = unwrapMessages(getClient(), result[0].transaction["out_msgs"], _getAbiArray())
        pprint(msgArray)

        print("---------------------")
        result = self.auction.finalize(msig=self.msig2, value=TON)
        msgArray = unwrapMessages(getClient(), result[0].transaction["out_msgs"], _getAbiArray())
        pprint(msgArray)


        #msgArray = unwrapMessages(getClient(), result[0].transaction["out_msgs"], _getAbiArray())
        #pprint(msgArray)

        result = self.auction.getInfo()
        print(result)

        result = self.domain.run(functionName="getWhois", functionParams={})
        print("msig:", self.msig.ADDRESS, "\nmsig2:", self.msig2.ADDRESS, "\nauction:", self.auction.ADDRESS, "\ndomain:", result["ownerAddress"])

    # 5. Cleanup
    def test_5(self):
        result = self.msig.destroy(addressDest = freeton_utils.giverGetAddress())
        self.assertEqual(result[1]["errorCode"], 0)
        result = self.msig2.destroy(addressDest = freeton_utils.giverGetAddress())
        self.assertEqual(result[1]["errorCode"], 0)

        result = self.domain.destroy(addressDest = freeton_utils.giverGetAddress())
        self.assertEqual(result[1]["errorCode"], 0)

# ==============================================================================
# 
unittest.main()
