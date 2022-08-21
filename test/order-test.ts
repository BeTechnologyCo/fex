/* eslint-disable no-await-in-loop */
import hre, { ethers, } from "hardhat";
import { BigNumber } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import { OrderBook } from "../typechain-types";
import { OrderDexToken } from "../typechain-types/contracts/order-dex-.sol";
import { WETH } from "../typechain-types/contracts/WETH";


describe('Order test', () => {
    let alice: SignerWithAddress;
    let bob: SignerWithAddress;
    let tom: SignerWithAddress;
    let deployer: SignerWithAddress;

    let WETH: WETH;
    let orderBook: OrderBook;
    let nativeToken: OrderDexToken;

    const initialSupply: BigNumber = ethers.utils.parseUnits("10000", 18);
    const oneToken: BigNumber = ethers.utils.parseUnits("1", 18);

    before(async () => {
        [deployer, alice, bob, tom] = await ethers.getSigners();

        WETH = await deployContract("WETH", initialSupply);
        nativeToken = await deployContract("OrderDexToken", initialSupply);
        orderBook = await deployContract("OrderBook", nativeToken.address, WETH.address);

        await nativeToken.transfer(alice.address, initialSupply.div(10));
    });


    it("create order", async () => {
        orderBook.createOrder(nativeToken.address, WETH.address, initialSupply.div(10), oneToken, true);
    });


});


async function deployContract(name: string, ...constructorArgs: any[]): Promise<any> {
    const factory = await ethers.getContractFactory(name);
    const contract = await factory.deploy(...constructorArgs);
    await contract.deployed();
    return contract;
}