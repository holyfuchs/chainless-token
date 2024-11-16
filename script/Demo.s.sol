pragma solidity ^0.8.22;

import "../contracts/ChainlessUSD.sol";
import "../contracts/ChainlessBalance.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";

contract MintZircuit is Script {
    function run() public {
        vm.createSelectFork(vm.rpcUrl("zircuit"));
        ChainlessUSD c = ChainlessUSD(payable(0xA8FF03a3aF16A07e505Fa7b5c1e3E2726D9787A3));

        vm.startBroadcast();
        c.mint(0x1337FA1246e4ABfFEFe3Ddd288968b4837FC6C8b, 1e18);
        vm.stopBroadcast();
    }
}

contract GetBalancePolygonAmoy is Script {
    function run() public {
        vm.createSelectFork(vm.rpcUrl("polygon"));
        ChainlessUSD c = ChainlessUSD(payable(0xA8FF03a3aF16A07e505Fa7b5c1e3E2726D9787A3));

        uint256 balance = c.balanceOf(0x1337FA1246e4ABfFEFe3Ddd288968b4837FC6C8b);
        console.log(balance);

        console.log("");
        console.log("internal balances:");
        // ChainlessBalance cb = c.chainlessBalance();
        int256 chainBalanceScroll = c.chainlessBalance().chainBalanceOf(0x1337FA1246e4ABfFEFe3Ddd288968b4837FC6C8b, 40170);
        int256 chainBalancePolygon = c.chainlessBalance().chainBalanceOf(0x1337FA1246e4ABfFEFe3Ddd288968b4837FC6C8b, 40267);
        int256 chainBalanceZircuit = c.chainlessBalance().chainBalanceOf(0x1337FA1246e4ABfFEFe3Ddd288968b4837FC6C8b, 40275);
        console.log(uint256(chainBalanceScroll));
        console.log(uint256(chainBalancePolygon));
        console.log(uint256(chainBalanceZircuit));

        // c.chainlessBalance().getChainsWithBalance(address(0x), 1000000000000010000);
    }
}

contract ApprovePolygonAmoy is Script {
    function run() public {
        vm.createSelectFork(vm.rpcUrl("polygon"));
        ChainlessUSD c = ChainlessUSD(payable(0xA8FF03a3aF16A07e505Fa7b5c1e3E2726D9787A3));

        vm.startBroadcast();
        c.approve(address(0x1337), 1000);
        vm.stopBroadcast();
    }
}
