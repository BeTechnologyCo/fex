import { HardhatUserConfig } from "hardhat/config";
import { task } from "hardhat/config";
import "@nomiclabs/hardhat-ethers";
import "@nomicfoundation/hardhat-chai-matchers";
import "@nomicfoundation/hardhat-toolbox";
import { config as dotEnvConfig } from "dotenv";

dotEnvConfig();

const privateKey = process.env.PRIVATE_KEY || "";
const privateKey2 = process.env.PRIVATE_KEY2 || "";
const privateKey3 = process.env.PRIVATE_KEY3 || "";
const privateKey4 = process.env.PRIVATE_KEY4 || "";

task("accounts", "Prints the list of accounts", async (args, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(await account.address);
  }
});

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.9",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  defaultNetwork: "hardhat",
  networks: {
    localhost: {
      url: "http://127.0.0.1:8545"
    },
    hardhat: {
      chainId: 1337,
      mining: {
        auto: true,
        interval: 5000
      },
      accounts: [
        {
          balance: "100000000000000000000",
          privateKey: privateKey,
        },
        {
          balance: "300000000000000000000",
          privateKey:
            privateKey2,
        },
        {
          balance: "60000000000000000000",
          privateKey:
            privateKey3,
        },
        {
          balance: "20000000000000000000",
          privateKey:
            privateKey4,
        },
      ],
    }

  },
};

export default config;
