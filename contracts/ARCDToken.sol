pragma solidity ^0.4.11;

import "./zeppelin/token/MintableToken.sol";

contract ARCDToken is MintableToken {
    string public constant name = "Arcade Token";
    string public constant symbol = "ARCD";
    uint8 public constant decimals = 18;
    string public version = "1.0";
}
