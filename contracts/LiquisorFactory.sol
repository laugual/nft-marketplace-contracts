pragma ton-solidity >=0.43.0;
pragma AbiHeader time;
pragma AbiHeader pubkey;
pragma AbiHeader expire;

//================================================================================
//
//import "../intertfaces/IMicroNft.sol";
//import "../contracts/MicroNft.sol";

//================================================================================
//
contract LiquisorFactory
{
    //========================================
    // Constants
    address constant addressZero = address.makeAddrStd(0, 0);

    //========================================
    // Error codes
    uint constant ERROR_MESSAGE_SENDER_IS_NOT_MY_OWNER = 100;

    //========================================
    // Variables

    //========================================
    // Modifiers
    function _reserve() internal inline view {    tvm.rawReserve(gasToValue(100000, 0), 0);    }

    modifier onlyOwner {    require(_ownerAddress == msg.sender, ERROR_MESSAGE_SENDER_IS_NOT_MY_OWNER);    _;    }
    modifier reserve   {    _reserve();                                                                    _;    }
}