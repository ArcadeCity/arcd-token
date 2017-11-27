var ATXCrowdsale = artifacts.require("./contracts/ATXCrowdsale.sol");
var ATXToken = artifacts.require("./contracts/ATXToken.sol");

function atxToWei(value){
    return value * (10**18);
}

contract('ATXCrowdsale', function(accounts) {
  let atxCrowdsale;
  let atxToken;

  let ethFundAddress;
  let atxDepositAddress;
  let saleStartTimestamp;
  let saleEndTimesamp;

  let alice;
  let bob;

  beforeEach(function() {
    currentTime = Math.floor(Date.now() / 1000);

    ethFundAddress = accounts[0];
    atxDepositAddress = accounts[1];
    saleStartTimestamp = currentTime - 1;
    saleEndTimesamp = currentTime + 10; // TODO: this might be a problem eventually

    alice = accounts[2];
    bob = accounts[3];

    return ATXCrowdsale.new(ethFundAddress, atxDepositAddress, saleStartTimestamp, saleEndTimesamp)
    .then(function(instance) {
      atxCrowdsale = instance;
      return atxCrowdsale.token();
    }).then(function(token) {
      atxToken = ATXToken.at(token);
    });
  });

  it("should seed initial address with tokens", function() {
    let atxFund = 92 * (10**8) * (10**18);

    return atxToken.balanceOf(atxDepositAddress)
    .then(function(balance) {
      assert.equal(balance.toNumber(), atxFund, "atx seed fund account should have 9.2B ATX");
    });
  });

  it("should allow tokens to be created and sent", function() {
    let initialBalanceFunding = web3.eth.getBalance(ethFundAddress).toNumber();

    return atxCrowdsale.createTokens({ from: alice, value: web3.toWei('1', 'ether') })
    .then(function() {
      return atxToken.balanceOf(alice);
    }).then(function(balance) {
      assert.equal(balance.toNumber(), atxToWei(200000), "alice should have 200000 ATX");
      return atxToken.transfer(bob, atxToWei(50000), { from: alice });
    }).then(function() {
      return atxToken.balanceOf(alice);
    }).then(function(balance) {
      assert.equal(balance.toNumber(), atxToWei(150000), "alice should have 50000 ATX less");
      return atxToken.balanceOf(bob);
    }).then(function(balance) {
      assert.equal(balance.toNumber(), atxToWei(50000), "bob should have 50000 ATX");

      diff = web3.eth.getBalance(ethFundAddress).toNumber() - initialBalanceFunding;
      assert.isAbove(diff, atxToWei(1 - 0.01), "Eth fund address should have 1 ETH more")
    });
  });

  it("Should not buy tokens, min amount limit", function(){
    return atxCrowdsale.createTokens({ from: alice, value: web3.toWei('0.09', 'ether') })
    .catch(function(exception){
        this.savedException = exception;
    }).then(function() {
        assert.isNotNull(savedException, "Should have throw an exception")
        return atxToken.balanceOf(alice);
    }).then(function(balance){
        assert.equal(balance.toNumber(), 0, "alice should have 0 ATX");
    });
  });
});
