import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-ethers";
import "@nomicfoundation/hardhat-verify";
import dotenv from "dotenv";
dotenv.config();

require("@openzeppelin/hardhat-upgrades");

const config: HardhatUserConfig = {
  solidity: "0.8.22",
  settings: {
    optimizer: {
      enabled: true,
      runs: 200,
    },
  },
  sourcify: {
    // Enable Sourcify verification by default
    enabled: true,
  },
  networks: {
    bitlayertestnet: {
      url: "https://testnet-rpc.bitlayer.org",
      chainId: 200810,
      // accounts: ["b5eb18473a135e9edf076c00df53d76575fa86bca530c7a650921161189a4ac"],
      accounts: [process.env.PRIVATE_KEY || ''],
    },
    bscTestnet: {
      url: "https://data-seed-prebsc-1-s3.binance.org:8545",
      chainId: 97,
      accounts: [process.env.BSC_PRIVATE_KEY || ''],
    },
    dbcTestnet: {
      url: "https://rpc-testnet.dbcwallet.io",
      accounts: [process.env.DBC_TEST_PRIVATE_KEY || ''],

      // accounts: {
      //   mnemonic: process.env.DBC_TEST_MNEMONIC || '',
      // },
      chainId: 19850818,
      timeout: 600000,
    },
    dbcMainnet: {
      url: "https://rpc.dbcwallet.io",
      accounts: [process.env.PRIVATE_KEY || ''],
      chainId: 19880818,
      timeout: 600000,
    },
    bsc: {
      url: process.env.BSC_RPC_URL || '',
      accounts: [process.env.BSC_PRIVATE_KEY || ''],
      chainId: 56,
    },
  },
  etherscan: {
    apiKey: {
      dbcTestnet: "no-api-key-needed",
      dbcMainnet: "no-api-key-needed",
      // An API key needs to be written as the hardhat-verify plugin will require it, and the verification will fail if it is not provided.
      // The current bitlayer browser has not yet enabled API key verification, so you can write any random string for now.
      bitlayertestnet: "1234",
      bscTestnet: process.env.BSC_TESTNET_API_KEY || '',
      bsc: process.env.BSC_API_KEY || '',
    },
    customChains: [
      {
        network: "bitlayertestnet",
        chainId: 200810,
        urls: {
          apiURL: "https://api-testnet.btrscan.com/scan/api",
          browserURL: "https://testnet.btrscan.com/",
        },
      },
      {
        network: "dbcTestnet",
        chainId: 19850818,
        urls: {
          apiURL: "https://blockscout-testnet.dbcscan.io/api",
          browserURL: "https://blockscout-testnet.dbcscan.io",
        },
      },
      {
        network: "dbcMainnet",
        chainId: 19880818,
        urls: {
          apiURL: "https://www.dbcscan.io/api",
          browserURL: "https://www.dbcscan.io",
        },
      },
      {
        network: "bsc",
        chainId: 56,
        urls: {
          apiURL: "https://bsc-dataseed.binance.org/api",
          browserURL: "https://bscscan.com",
        },
      },
    ],
  },
};

export default config;
