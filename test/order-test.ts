/* eslint-disable no-await-in-loop */
import hre, { ethers } from "hardhat";
import { BigNumber, ContractTransaction } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import { OrderBook, TestToken } from "../typechain-types";
import { WETH } from "../typechain-types/contracts/WETH";
import { OrderDexToken } from "../typechain-types/contracts/OrderDexToken";
import { expect } from "chai";
import { any } from "hardhat/internal/core/params/argumentTypes";

describe('Order test', () => {
    let alice: SignerWithAddress;
    let bob: SignerWithAddress;
    let tom: SignerWithAddress;
    let deployer: SignerWithAddress;

    let WETH: WETH;
    let orderBook: OrderBook;
    let nativeToken: OrderDexToken;
    let testToken: TestToken;

    const initialSupply: BigNumber = ethers.utils.parseUnits("10000", 18);
    const oneToken: BigNumber = ethers.utils.parseUnits("1", 18);
    const oneTestToken: BigNumber = ethers.utils.parseUnits("1", 6);

    before(async () => {
        [deployer, alice, bob, tom] = await ethers.getSigners();

        WETH = await deployContract("WETH");
        nativeToken = await deployContract("OrderDexToken", initialSupply);
        testToken = await deployContract("TestToken");
        orderBook = await deployContract("OrderBook", nativeToken.address, WETH.address);

        await nativeToken.transfer(alice.address, initialSupply.div(10));
        await testToken.transfer(bob.address, oneTestToken.mul(10000));
    });


    it("match order", async () => {
        let balanceAliceEth = await ethers.provider.getBalance(alice.address);
        let balanceAliceToken = await nativeToken.balanceOf(alice.address);

        let txApprove: ContractTransaction = await nativeToken.connect(alice).approve(orderBook.address, oneToken.mul(10));
        let approvePrice = await getGasCost(txApprove);
        let txOrder: ContractTransaction = await orderBook.connect(alice).createOrder(nativeToken.address, WETH.address, oneToken.mul(10), oneToken, true);
        let orderPrice = await getGasCost(txOrder);

        let balanceBobEth = await ethers.provider.getBalance(bob.address);
        let balanceBobToken = await nativeToken.balanceOf(bob.address);
        await orderBook.connect(bob).createOrderFromETH(nativeToken.address, oneToken.mul(10), { value: oneToken });
        await orderBook.sellOrder(1, [0]);

        let balanceAliceEthAfter = await ethers.provider.getBalance(alice.address);
        let balanceAliceTokenAfter = await nativeToken.balanceOf(alice.address);
        let balanceBobEthAfter = await ethers.provider.getBalance(bob.address);
        let balanceBobTokenAfter = await nativeToken.balanceOf(bob.address);

        // get 1 eth
        expect(balanceAliceEthAfter).to.equal(balanceAliceEth.add(oneToken).sub(approvePrice).sub(orderPrice));
        // get 10 tokens
        expect(balanceBobTokenAfter).to.equal(balanceBobToken.add(oneToken.mul(10)));
    });

    it("match erc20 order", async () => {
        // todo finalize test
        let balanceAliceTestToken = await testToken.balanceOf(alice.address);
        let balanceBobTestToken = await testToken.balanceOf(bob.address);
        let balanceAliceToken = await nativeToken.balanceOf(alice.address);
        let balanceBobToken = await nativeToken.balanceOf(bob.address);

        let txApprove: ContractTransaction = await nativeToken.connect(alice).approve(orderBook.address, oneToken.mul(10));
        let approvePrice = await getGasCost(txApprove);
        let txOrder: ContractTransaction = await orderBook.connect(alice).createOrder(nativeToken.address, WETH.address, oneToken.mul(10), oneToken, true);
        let orderPrice = await getGasCost(txOrder);

        let balanceBobEth = await ethers.provider.getBalance(bob.address);
        balanceBobToken = await nativeToken.balanceOf(bob.address);
        await orderBook.connect(bob).createOrderFromETH(nativeToken.address, oneToken.mul(10), { value: oneToken });
        await orderBook.sellOrder(1, [0]);

        let balanceAliceEthAfter = await ethers.provider.getBalance(alice.address);
        let balanceAliceTokenAfter = await nativeToken.balanceOf(alice.address);
        let balanceBobEthAfter = await ethers.provider.getBalance(bob.address);
        let balanceBobTokenAfter = await nativeToken.balanceOf(bob.address);

        // get 1 eth
        expect(balanceAliceEthAfter).to.equal(balanceAliceTestToken.add(oneToken).sub(approvePrice).sub(orderPrice));
        // get 10 tokens
        expect(balanceBobTokenAfter).to.equal(balanceBobToken.add(oneToken.mul(10)));
    });

});


async function deployContract(name: string, ...constructorArgs: any[]): Promise<any> {
    const factory = await ethers.getContractFactory(name);
    const contract = await factory.deploy(...constructorArgs);
    await contract.deployed();
    return contract;
}

async function getGasCost(tx: ContractTransaction): Promise<BigNumber> {
    let result = await tx.wait();
    return result.cumulativeGasUsed.mul(result.effectiveGasPrice);
}