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
To test in local create .env file and add 4 private key like
PRIVATE_KEY = 0xaaaaaaaaa....
PRIVATE_KEY2 = 0xbbbbbbbb....
PRIVATE_KEY3 = 0xccccccccc....
PRIVATE_KEY4 = 0xdddddddd....

Test
npx hardhat test .\test\order-test.ts
