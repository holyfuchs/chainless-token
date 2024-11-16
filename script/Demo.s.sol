pragma solidity ^0.8.22;

import "../contracts/ChainlessUSD.sol";
import "../contracts/ChainlessBalance.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";

contract MintZircuit is Script {
    function run() public {
        vm.createSelectFork(vm.rpcUrl("zircuit"));
        ChainlessUSD c = ChainlessUSD(payable(0x753da027758f33f9dF35b8529Fa9b2e78664DfE5));

        vm.startBroadcast();
        c.mint(0x1337FA1246e4ABfFEFe3Ddd288968b4837FC6C8b, 100e18);
        vm.stopBroadcast();
    }
}

contract GetBalancePolygonAmoy is Script {
    function run() public {
        vm.createSelectFork(vm.rpcUrl("polygon"));
        ChainlessUSD c = ChainlessUSD(payable(0x753da027758f33f9dF35b8529Fa9b2e78664DfE5));

        uint256 balance = c.balanceOf(0x1337FA1246e4ABfFEFe3Ddd288968b4837FC6C8b);
        console.log("balance polygon:");
        console.log(balance);

        // ChainlessBalance cb = c.chainlessBalance();
        // int256 chainBalanceScroll = c.chainlessBalance().chainBalanceOf(0x1337FA1246e4ABfFEFe3Ddd288968b4837FC6C8b, 40170);
        int256 chainBalancePolygon = c.chainlessBalance().chainBalanceOf(0x1337FA1246e4ABfFEFe3Ddd288968b4837FC6C8b, 40267);
        int256 chainBalanceZircuit = c.chainlessBalance().chainBalanceOf(0x1337FA1246e4ABfFEFe3Ddd288968b4837FC6C8b, 40275);
        // console.log(uint256(chainBalanceScroll));
        console.log("internal balance polygon:");
        console.log(uint256(chainBalancePolygon));
        console.log("internal balance zircuit:");
        console.log(uint256(chainBalanceZircuit));

        // c.chainlessBalance().getChainsWithBalance(0x1337FA1246e4ABfFEFe3Ddd288968b4837FC6C8b, 100e18);
    }
}

contract ApprovePolygonAmoy is Script {
    function run() public {
        vm.createSelectFork(vm.rpcUrl("polygon"));
        ChainlessUSD c = ChainlessUSD(payable(0x753da027758f33f9dF35b8529Fa9b2e78664DfE5));

        vm.startBroadcast();
        c.approve(address(0x1337), 100e18);
        vm.stopBroadcast();
    }
}

contract GetAllowance is Script {
    function run() public {
        vm.createSelectFork(vm.rpcUrl("polygon"));
        ChainlessUSD c = ChainlessUSD(payable(0x753da027758f33f9dF35b8529Fa9b2e78664DfE5));


        uint256 allowance = c.allowance(0x1337FA1246e4ABfFEFe3Ddd288968b4837FC6C8b, address(0x1337));
        console.log("allowance"); 
        console.log(allowance);

        // ChainlessBalance cb = c.chainlessBalance();
        // int256 chainBalanceScroll = c.chainlessBalance().chainBalanceOf(0x1337FA1246e4ABfFEFe3Ddd288968b4837FC6C8b, 40170);
        int256 chainBalancePolygon = c.chainlessBalance().chainBalanceOf(0x1337FA1246e4ABfFEFe3Ddd288968b4837FC6C8b, 40267);
        int256 chainBalanceZircuit = c.chainlessBalance().chainBalanceOf(0x1337FA1246e4ABfFEFe3Ddd288968b4837FC6C8b, 40275);
        // console.log(uint256(chainBalanceScroll));
        console.log("internal balance polygon:");
        console.log(uint256(chainBalancePolygon));
        console.log("internal balance zircuit:");
        console.log(uint256(chainBalanceZircuit));
    }
}
