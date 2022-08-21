import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();

  const initialSupply = ethers.utils.parseUnits("10000", 18);
  const nativeToken = await deployContract("OrderDexToken", initialSupply);
  const orderBook = await deployContract("OrderBook", nativeToken.address, "0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889");


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

