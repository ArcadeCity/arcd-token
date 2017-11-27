var ATXCrowdsale = artifacts.require("./ATXCrowdsale.sol");

module.exports = function(deployer, network, accounts) {
  deployer.deploy(ATXCrowdsale);
};
