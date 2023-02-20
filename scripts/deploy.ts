import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  let wFTM = "0xf1277d1ed8ad466beddf92ef448a132661956621";
  const { chainId } = await ethers.provider.getNetwork();
  if (chainId === 250) {
    wFTM = "0x21be370d5312f44cb42ce377bc9b8a0cef1a4c83";
  }

  const initialSupply = ethers.utils.parseUnits("10000", 18);
  const nativeToken = await deployContract("OrderDexToken", initialSupply);
  const orderBook = await deployContract("OrderBook", nativeToken.address, wFTM);


  console.log(`native token address ${nativeToken.address}`);
  console.log(`order book address ${orderBook.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

async function deployContract(name: string, ...constructorArgs: any[]): Promise<any> {
  const factory = await ethers.getContractFactory(name);
  const contract = await factory.deploy(...constructorArgs);
  await contract.deployed();
  return contract;
}

