pragma solidity ^0.4.18;

import "./zeppelin/token/StandardToken.sol";
import "./zeppelin/math/SafeMath.sol";
import "./ATXToken.sol";

contract Crowdsale {
    function buyTokens(address _recipient) public payable;
}

contract ATXCrowdsale is Crowdsale {
    using SafeMath for uint256;

    // metadata
    uint256 public constant decimals = 18;

    // contracts
    address public ethFundDeposit;      // deposit address for ETH for Arcade City
    address public atxFundDeposit;      // deposit address for Arcade City use and ATX User Fund

    // crowdsale parameters
    bool public isFinalized;              // switched to true in operational state
    uint256 public fundingStartTimestamp;
    uint256 public fundingEndTimestamp;
    uint256 public constant atxFund = 92 * (10**8) * 10**decimals;   // 9.2B for Arcade City
    uint256 public constant tokenExchangeRate = 200000; // 200,000 ATX tokens per 1 ETH
    uint256 public constant tokenCreationCap =  10 * (10**9) * 10**decimals; // 10B total
    uint256 public constant minBuyTokens = 20000 * 10**decimals; // 0.1 ETH
    uint256 public constant gasPriceLimit = 60 * 10**9; // Gas limit 60 gwei

    // events
    event CreateATX(address indexed _to, uint256 _value);

    ATXToken public token;

    // constructor
    function ATXCrowdsale (
      address _ethFundDeposit,
      address _atxFundDeposit,
      uint256 _fundingStartTimestamp,
      uint256 _fundingEndTimestamp
    )
      public
    {
      token = new ATXToken();

      // sanity checks
      assert(_ethFundDeposit != 0x0);
      assert(_atxFundDeposit != 0x0);
      assert(_fundingStartTimestamp < _fundingEndTimestamp);
      assert(uint256(token.decimals()) == decimals);

      isFinalized = false;                   //controls pre through crowdsale state
      ethFundDeposit = _ethFundDeposit;
      atxFundDeposit = _atxFundDeposit;
      fundingStartTimestamp = _fundingStartTimestamp;
      fundingEndTimestamp = _fundingEndTimestamp;

      token.mint(atxFundDeposit, atxFund);
      CreateATX(atxFundDeposit, atxFund);
    }

    /// @dev Accepts ether and creates new ATX tokens.
    function createTokens() payable external {
      buyTokens(msg.sender);
    }

    // low level token purchase function
    function buyTokens(address beneficiary) payable public {
      require (!isFinalized);
      require (block.timestamp >= fundingStartTimestamp);
      require (block.timestamp <= fundingEndTimestamp);
      require (msg.value != 0);
      require (beneficiary != 0x0);
      require (tx.gasprice <= gasPriceLimit);

      uint256 tokens = msg.value.mul(tokenExchangeRate); // check that we're not over totals
      uint256 checkedSupply = token.totalSupply().add(tokens);

      // return money if something goes wrong
      require (tokenCreationCap >= checkedSupply);

      // return money if tokens is less than the min amount
      // the min amount does not apply if the availables tokens are less than the min amount.
      require (tokens >= minBuyTokens || (tokenCreationCap.sub(token.totalSupply())) <= minBuyTokens);

      token.mint(beneficiary, tokens);
      CreateATX(beneficiary, tokens);  // logs token creation

      forwardFunds();
    }

    function finalize() public {
      require (!isFinalized);
      require (block.timestamp > fundingEndTimestamp || token.totalSupply() == tokenCreationCap);
      require (msg.sender == ethFundDeposit);
      isFinalized = true;
      token.finishMinting();
    }

    // send ether to the fund collection wallet
    function forwardFunds() internal {
      ethFundDeposit.transfer(msg.value);
    }
}
