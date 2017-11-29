var ARCDCrowdsale = artifacts.require("./contracts/ARCDCrowdsale.sol");
var ARCDToken = artifacts.require("./contracts/ARCDToken.sol");

function arcdToWei(value){
    return value * (10**18);
}

contract('ARCDCrowdsale', function(accounts) {
  let arcdCrowdsale;
  let arcdToken;

  let ethFundAddress;
  let arcdDepositAddress;
  let saleStartTimestamp;
  let saleEndTimesamp;

  let alice;
  let bob;

  beforeEach(function() {
    currentTime = Math.floor(Date.now() / 1000);

    ethFundAddress = accounts[1];
    arcdDepositAddress = accounts[2];
    saleStartTimestamp = currentTime - 1;
    saleEndTimesamp = currentTime + 10; // TODO: this might be a problem eventually if tests start taking longer than 10 seconds to execute

    alice = accounts[3];
    bob = accounts[4];

    return ARCDCrowdsale.new(ethFundAddress, arcdDepositAddress, saleStartTimestamp, saleEndTimesamp)
    .then(function(instance) {
      arcdCrowdsale = instance;
      return arcdCrowdsale.token();
    }).then(function(token) {
      arcdToken = ARCDToken.at(token);
    });
  });

  it("should seed initial address with tokens", function() {
    let arcdFund = 92 * (10**8) * (10**18);

    return arcdToken.balanceOf(arcdDepositAddress)
    .then(function(balance) {
      assert.equal(balance.toNumber(), arcdFund, "arcd seed fund account should have 9.2B ARCD");
    });
  });

  it("should allow tokens to be created and sent", function() {
    let initialBalanceFunding = web3.eth.getBalance(ethFundAddress).toNumber();

    return arcdCrowdsale.createTokens({ from: alice, value: web3.toWei('1', 'ether'), gasPrice: 60000000000 })
    .then(function() {
      return arcdToken.balanceOf(alice);
    }).then(function(balance) {
      assert.equal(balance.toNumber(), arcdToWei(200000), "alice should have 200000 ARCD");
      return arcdToken.transfer(bob, arcdToWei(50000), { from: alice });
    }).then(function() {
      return arcdToken.balanceOf(alice);
    }).then(function(balance) {
      assert.equal(balance.toNumber(), arcdToWei(150000), "alice should have 50000 ARCD less");
      return arcdToken.balanceOf(bob);
    }).then(function(balance) {
      assert.equal(balance.toNumber(), arcdToWei(50000), "bob should have 50000 ARCD");

      diff = web3.eth.getBalance(ethFundAddress).toNumber() - initialBalanceFunding;
      assert.isAbove(diff, arcdToWei(1 - 0.01), "Eth fund address should have 1 ETH more")
    });
  });

  it("Should not buy tokens, min amount limit", function(){
    return arcdCrowdsale.createTokens({ from: alice, value: web3.toWei('0.09', 'ether'), gasPrice: 60000000000 })
    .catch(function(exception){
        this.savedException = exception;
    }).then(function() {
        assert.isNotNull(savedException, "Should have throw an exception")
        return arcdToken.balanceOf(alice);
    }).then(function(balance){
        assert.equal(balance.toNumber(), 0, "alice should have 0 ARCD");
    });
  });

  it("Should not buy tokens, gas price too high", function(){
    return arcdCrowdsale.createTokens({ from: alice, value: web3.toWei('1', 'ether'), gasPrice: 60000000001 })
    .catch(function(exception){
        this.savedException = exception;
    }).then(function() {
        assert.isNotNull(savedException, "Should have throw an exception")
        return arcdToken.balanceOf(alice);
    }).then(function(balance){
        assert.equal(balance.toNumber(), 0, "alice should have 0 ARCD");
    });
  });
});
