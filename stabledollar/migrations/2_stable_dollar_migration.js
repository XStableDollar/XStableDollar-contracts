const XStableDollar = artifacts.require("XStableDollar");

module.exports = function (deployer, network, accounts) {
    deployer.deploy(XStableDollar, accounts[0]).then(async (GameControlInstance) => {
      console.log('success');
    });
};

// truffle migration --f 2 --to 2 --network rinkeby
// truffle migration --network ganache