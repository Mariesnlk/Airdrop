const path = require("path");
require('dotenv').config({ path: './.env' });
const HDWalletProvider = require("@truffle/hdwallet-provider");
const MetaMaskAccountIndex = 0;

module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
  contracts_build_directory: path.join(__dirname, "client/src/contracts"),
  development: {
    port: 7545,
    network_id: "*",
    host: "127.0.0.1"
  },
  ganache_local: {
    provider: function () {
      return new HDWalletProvider(process.env.MNEMONIC, "http://127.0.0.1:7545", MetaMaskAccountIndex)
    },
    network_id: 5777
  },
  networks: {
    ropsten: {
      provider: function () {
        return new HDWalletProvider(process.env.MNEMONIC, `wss://ropsten.infura.io/ws/v3/${process.env.PROJECT_ID}`)
      },
      network_id: 3,
      gas: 4000000,
      networkCheckTimeoutnetworkCheckTimeout: 10000,
      timeoutBlocks: 200
    }
  },
  plugins: ['truffle-plugin-verify'],
  plugins: ["solidity-coverage"],
  api_keys: {
    etherscan: process.env.ETHERSCAN_API_KEY
  },
  compilers: {
    solc: {
      version: "^0.8.0"
    }
  }
};