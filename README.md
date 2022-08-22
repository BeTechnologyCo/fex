# Order Book decentralized

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a script that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
GAS_REPORT=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.ts
```
# Test in local
To test in local create .env file and add 4 private key and execute script

PRIVATE_KEY = 0xaaaaaaaaa....
PRIVATE_KEY2 = 0xbbbbbbbb....
PRIVATE_KEY3 = 0xccccccccc....
PRIVATE_KEY4 = 0xdddddddd....

npx hardhat test .\test\order-test.ts
## Deploy on local
To deploy in mumbai or local node add deployer key on .env file and execute script (we used a mumbai fork)

DEPLOYER_KEY = 0xaaaaaaaaa....

npx hardhat node

npx hardhat run scripts/deploy.ts
## Deploy on  mumbai
To deploy in mumbai or local node add deployer key on .env file and execute script

DEPLOYER_KEY = 0xaaaaaaaaa....

npx hardhat run scripts/deploy.ts --network matic

Native token address (mumbai) : 0x5bd8391CBC43eE396F5614A517691C7d08268333

Order Book address (mumbai) : 0x4Ef296cB9a061d1a7285A08D2252F82Ef3082071

## Licensing

The primary license for Order Book Dex is the Business Source License 1.1 (BUSL-1.1), see LICENSE. However, some files are dual licensed under GPL-2.0-or-later
