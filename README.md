# Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a script that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
GAS_REPORT=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.ts
```
# Order Book decentralized
To test in local create .env file and add 4 private key and execute script

PRIVATE_KEY = 0xaaaaaaaaa....
PRIVATE_KEY2 = 0xbbbbbbbb....
PRIVATE_KEY3 = 0xccccccccc....
PRIVATE_KEY4 = 0xdddddddd....

npx hardhat test .\test\order-test.ts

## Deploy on mumbai
To deploy in mumbai add deployer key on .env file and execute script

DEPLOYER_KEY = 0xaaaaaaaaa....

npx hardhat run scripts/deploy.ts --network matic

Native token address (mumbai) : 0x5bd8391CBC43eE396F5614A517691C7d08268333
Order Book address (mumbai) : 0xB79aF1F3dD7e25Da902363ef5E220470b9288021