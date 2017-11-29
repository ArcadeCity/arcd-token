pragma solidity ^0.4.11;

import "./zeppelin/token/StandardToken.sol";
import "./zeppelin/math/SafeMath.sol";
import "./ARCDToken.sol";

contract Crowdsale {
    function buyTokens(address _recipient) public payable;
}

contract ARCDCrowdsale is Crowdsale {
    using SafeMath for uint256;

    // metadata
    uint256 public constant decimals = 18;

    // contracts
    // deposit address for ETH for Arcade City
    address public constant ETH_FUND_DEPOSIT = 0x3b2470E99b402A333a82eE17C3244Ff04C79Ec6F;
    // deposit address for Arcade City use and ARCD User Fund
    address public constant ARCD_FUND_DEPOSIT = 0x3b2470E99b402A333a82eE17C3244Ff04C79Ec6F;

    // crowdsale parameters
    bool public isFinalized;                                                    // switched to true in operational state
    uint256 public constant FUNDING_START_TIMESTAMP = 1511919480;               // 11/29/2017 @ 1:38am UTC
    uint256 public constant FUNDING_END_TIMESTAMP = FUNDING_START_TIMESTAMP + (60 * 60 * 24 * 90); // 90 days
    uint256 public constant ARCD_FUND = 92 * (10**8) * 10**decimals;            // 9.2B for Arcade City
    uint256 public constant TOKEN_EXCHANGE_RATE = 200000;                       // 200,000 ARCD tokens per 1 ETH
    uint256 public constant TOKEN_CREATION_CAP =  10 * (10**9) * 10**decimals;  // 10B total
    uint256 public constant MIN_BUY_TOKENS = 20000 * 10**decimals;              // 0.1 ETH
    uint256 public constant GAS_PRICE_LIMIT = 60 * 10**9;                       // Gas limit 60 gwei

    // events
    event CreateARCD(address indexed _to, uint256 _value);

    ARCDToken public token;

    // constructor
    function ARCDCrowdsale () public {
      token = new ARCDToken();

      // sanity checks
      assert(ETH_FUND_DEPOSIT != 0x0);
      assert(ARCD_FUND_DEPOSIT != 0x0);
      assert(FUNDING_START_TIMESTAMP < FUNDING_END_TIMESTAMP);
      assert(uint256(token.decimals()) == decimals);

      isFinalized = false;

      token.mint(ARCD_FUND_DEPOSIT, ARCD_FUND);
      CreateARCD(ARCD_FUND_DEPOSIT, ARCD_FUND);
    }

    /// @dev Accepts ether and creates new ARCD tokens.
    function createTokens() payable external {
      buyTokens(msg.sender);
    }

    function () public payable {
      buyTokens(msg.sender);
    }

    // low level token purchase function
    function buyTokens(address beneficiary) public payable {
      require (!isFinalized);
      require (block.timestamp >= FUNDING_START_TIMESTAMP);
      require (block.timestamp <= FUNDING_END_TIMESTAMP);
      require (msg.value != 0);
      require (beneficiary != 0x0);
      require (tx.gasprice <= GAS_PRICE_LIMIT);

      uint256 tokens = msg.value.mul(TOKEN_EXCHANGE_RATE); // check that we're not over totals
      uint256 checkedSupply = token.totalSupply().add(tokens);

      // return money if something goes wrong
      require (TOKEN_CREATION_CAP >= checkedSupply);

      // return money if tokens is less than the min amount
      // the min amount does not apply if the availables tokens are less than the min amount.
      require (tokens >= MIN_BUY_TOKENS || (TOKEN_CREATION_CAP.sub(token.totalSupply())) <= MIN_BUY_TOKENS);

      token.mint(beneficiary, tokens);
      CreateARCD(beneficiary, tokens);  // logs token creation

      forwardFunds();
    }

    function finalize() public {
      require (!isFinalized);
      require (block.timestamp > FUNDING_END_TIMESTAMP || token.totalSupply() == TOKEN_CREATION_CAP);
      require (msg.sender == ETH_FUND_DEPOSIT);
      isFinalized = true;
      token.finishMinting();
    }

    // send ether to the fund collection wallet
    function forwardFunds() internal {
      ETH_FUND_DEPOSIT.transfer(msg.value);
    }
}
