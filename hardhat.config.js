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
    version: "0.8.2",
    settings: {
      optimizer: {
        enabled: true,
        runs: 2000,
        
      }
    }
  },
  networks: {
    fantom_testnet: {
      url: `https://xapi.testnet.fantom.network/lachesis/`,
      gasPrice: 420000000000,
      
      accounts: [`ed81990a339aa50c992a81bd778150f65ec68e0d557cd074e14b91d0a4d08a97`]
    },
    mainnet: {
      url: `https://eth-mainnet.alchemyapi.io/v2/EdwQzJSSPMuRDwoSQE6q0O3sXLxdMl-9`,
      accounts: [`ed81990a339aa50c992a81bd778150f65ec68e0d557cd074e14b91d0a4d08a97`],
      gasPrice: 47000000000 
    },
    fantom: {
      url: `https://rpc.ftm.tools/`,
      gasPrice: 300000000000,
      
      accounts: [`ed81990a339aa50c992a81bd778150f65ec68e0d557cd074e14b91d0a4d08a97`]
    },
    matic_testnet: {
      url: `https://matic-mumbai.chainstacklabs.com/`,
      gasPrice: 300000000000,
      
      accounts: [`ed81990a339aa50c992a81bd778150f65ec68e0d557cd074e14b91d0a4d08a97`]
    },
    matic: {
      url: `https://polygon-rpc.com/`,
      gasPrice: 300000000000,
      
      accounts: [`ed81990a339aa50c992a81bd778150f65ec68e0d557cd074e14b91d0a4d08a97`]
    },
    bsc_testnet: {
      url: `https://data-seed-prebsc-1-s1.binance.org:8545/`,
      gasPrice: 300000000000,
      
      accounts: [`ed81990a339aa50c992a81bd778150f65ec68e0d557cd074e14b91d0a4d08a97`]
    }
  },
  etherscan: {
    apiKey: "EATS2BCT8S8ZISVMNA4CYE8U3TGE136KEF"
  }
};
