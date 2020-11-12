const XStableGovernanceToken = artifacts.require("XStableGovernanceToken");

module.exports = function (deployer, network, accounts) {
    deployer.deploy(XStableGovernanceToken, accounts[0]).then(async (GameControlInstance) => {
      console.log('success');
    });
};

// truffle migration --f 2 --to 2 --network rinkeby
// truffle migration --network ganache