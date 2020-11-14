const fs = require('fs');
require('dotenv').config();

const HDWalletProvider = require('@truffle/hdwallet-provider');
const infuraKey = process.env.infuraKey;
const privatekey = process.env.privatekey;

const BSC_RPC = "https://data-seed-prebsc-1-s1.binance.org:8545/"
// https://testnet.binance.org/faucet-smart bsc水龙头

module.exports = {
  networks: {
    ganache: {
      host: "127.0.0.1", // Localhost (default: none)
      port: 7545, // Standard Ethereum port (default: none)
      network_id: "*", // Any network (default: none)
      gas: 6000000,
    },
    rinkeby: {
      provider: () => new HDWalletProvider(privatekey, `https://rinkeby.infura.io/v3/` + infuraKey),
      network_id: 4,
      gas: 9000000,
      confirmations: 1, // # of confs to wait between deployments. (default: 0)
      timeoutBlocks: 50, // # of blocks before a deployment times out  (minimum/default: 50)
      skipDryRun: true
    },
    bsc: {
      provider: () => new HDWalletProvider(privatekey, BSC_RPC),
      network_id: 97,
      gas: 9000000,
      confirmations: 1, // # of confs to wait between deployments. (default: 0)
      timeoutBlocks: 50, // # of blocks before a deployment times out  (minimum/default: 50)
      skipDryRun: true
    },
    // Configuration for Loom Testnet
    loom_testnet: {
      provider: function() {
          const privateKey = 'YOUR_PRIVATE_KEY';
          const chainId = 'extdev-plasma-us1';
          const writeUrl = 'wss://extdev-basechain-us1.dappchains.com/websocket';
          const readUrl = 'wss://extdev-basechain-us1.dappchains.com/queryws';
          // TODO: Replace the line below
          return new LoomTruffleProvider(chainId, writeUrl, readUrl, privateKey);
      },
      network_id: '9545242630824'
    }
  },

  // Set default mocha options here, use special reporters etc.
  mocha: {
    // timeout: 100000
  },

  // Configure your compilers
  compilers: {
    solc: {
      version: "0.6.12",    // Fetch exact version from solc-bin (default: truffle's version)
      optimizer: {
         enabled: true,
         runs: 200
       },
    },
  },
};
