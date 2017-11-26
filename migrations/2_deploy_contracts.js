var ATXCrowdsale = artifacts.require("./ATXCrowdsale.sol");
var ATXToken = artifacts.require("./ATXToken.sol");

module.exports = function(deployer, network, accounts) {
  deployer.deploy(ATXToken);
  deployer.deploy(ATXCrowdsale);
};
