require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require('@nomiclabs/hardhat-ethers');
// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html


// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
 require("@nomiclabs/hardhat-waffle");
 require('@nomiclabs/hardhat-ethers');
 require('@openzeppelin/hardhat-upgrades');
module.exports = {
  solidity: {
    version: "0.8.11",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000
      }
    }
  },
  networks: {
    fantom_testnet: {
      url: `https://xapi.testnet.fantom.network/lachesis/`,
      gasPrice: process.env.GAS_PRICE,
      
      accounts: [process.env.PRIVATE_KEY]
    },
    bsc_testnet: {
      url: `https://data-seed-prebsc-1-s1.binance.org:8545/`,
      gasPrice: process.env.GAS_PRICE,
      
      accounts: [process.env.PRIVATE_KEY]
    }
  },
  etherscan: {
    apiKey: process.env.API_KEY
  }
};
