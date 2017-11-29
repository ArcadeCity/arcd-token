var ARCDCrowdsale = artifacts.require("./ARCDCrowdsale.sol");

module.exports = function(deployer, network, accounts) {
  deployer.deploy(ARCDCrowdsale);
};
