// // SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.22;

import {ChainlessUSD} from "../contracts/ChainlessUSD.sol";

import "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";

contract DeployedToken is Test {
    ChainlessUSD token;

    function setUp() public virtual {
        token = ChainlessUSD(payable(0xA8FF03a3aF16A07e505Fa7b5c1e3E2726D9787A3));
    }

    // function test_balance() public {
    //     uint256 bal = token.balanceOf(0x1337FA1246e4ABfFEFe3Ddd288968b4837FC6C8b);
    //     console.log(bal);
    // }

    // function test_get_chains_with_balance() public {
    //     // token.chainlessBalance().balanceOf()
    //     // uint256 bal = token.balanceOf(0x1337FA1246e4ABfFEFe3Ddd288968b4837FC6C8b);
    // }
}
