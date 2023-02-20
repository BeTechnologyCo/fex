// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestToken is ERC20 {
    constructor() ERC20("TestToken", "TT") {
        _mint(msg.sender, 100000 * 10 ** decimals());
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }
}