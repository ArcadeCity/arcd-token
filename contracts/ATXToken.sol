pragma solidity ^0.4.18;

import "./zeppelin/token/MintableToken.sol";

contract ATXToken is MintableToken {
    string public constant name = "Arcade Token";
    string public constant symbol = "ATX";
    uint8 public constant decimals = 18;
    string public version = "1.0";
}
