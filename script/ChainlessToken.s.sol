pragma solidity ^0.8.22;

import "../contracts/ChainlessUSD.sol";

// import "forge-std/Test.sol";
import "forge-std/Script.sol";
import { Util } from "../contracts/Util.sol";

contract Deploy is Script {
    struct Endpoint {
        string rpcAlias;
        address endpoint;
    }
    Endpoint[] public e;

    function setUp() public {
        // e.push(Endpoint("sepolia", 0x6EDCE65403992e310A62460808c4b910D972f10f));
        // e.push(Endpoint("scroll", 0x6EDCE65403992e310A62460808c4b910D972f10f));
        e.push(Endpoint("polygon", 0x6EDCE65403992e310A62460808c4b910D972f10f));
        e.push(Endpoint("zircuit", 0x6EDCE65403992e310A62460808c4b910D972f10f));
    }

    function run() public {
        uint i = 0;
        // string memory rpcAlias = e[i].rpcAlias;
        // vm.createSelectFork(vm.rpcUrl(rpcAlias));
        vm.startBroadcast();
        ChainlessUSD cb = new ChainlessUSD("Unchained USD", "UUSD", e[i].endpoint, msg.sender);
        vm.stopBroadcast();
        // console.log(string.concat("deployed on: ", rpcAlias, " at: ", vm.toString(address(cb))));
    }

    // function run() public {
    //     for (uint i = 0; i < e.length; i++) {
    //         string memory rpcAlias = e[i].rpcAlias;
    //         vm.createSelectFork(vm.rpcUrl(rpcAlias));
    //         vm.startBroadcast();
    //         ChainlessUSD cb = new ChainlessUSD("Unchained USD", "UUSD", e[i].endpoint, msg.sender);
    //         vm.stopBroadcast();
    //         console.log(string.concat("deployed on: ", rpcAlias, " at: ", vm.toString(address(cb))));
    //     }
    // }
}

contract Connect is Script {
    struct Peer {
        string rpcAlias;
        uint32 eid;
        address peer;
    }
    Peer[] public peers;

    function setUp() public {
        // peers.push(Peer("unichain", 40333, 0xaC45aaab89741702a9A0083E28fbcfe28ffE7a96));
        // peers.push(Peer("scroll", 40170, 0xA8FF03a3aF16A07e505Fa7b5c1e3E2726D9787A3));
        peers.push(Peer("polygon", 40267, 0x753da027758f33f9dF35b8529Fa9b2e78664DfE5));
        peers.push(Peer("zircuit", 40275, 0x753da027758f33f9dF35b8529Fa9b2e78664DfE5));
    }

    // function run() public {
    //     uint i = 2;

    //     vm.createSelectFork(vm.rpcUrl(peers[i].rpcAlias));
    //     ChainlessToken lz = ChainlessToken(payable(peers[i].peer));

    //     vm.startBroadcast();
    //     lz.setChainlessBalance(0x2C9b1a5EE1C9C5b7dA8a4d7bECF4e6D5D813f444);
    //     vm.stopBroadcast();

    //     for (uint j = 0; j < peers.length; j++) {
    //         if (i == j) continue;
    //         vm.startBroadcast();
    //         lz.addDestination(peers[j].eid);
    //         lz.setPeer(peers[j].eid, Util.addressToBytes32(peers[j].peer));
    //         vm.stopBroadcast();
    //     }
    // }

    function run() public {
        for (uint i = 0; i < peers.length; i++) {
            vm.createSelectFork(vm.rpcUrl(peers[i].rpcAlias));
            ChainlessToken lz = ChainlessToken(payable(peers[i].peer));

            vm.startBroadcast();
            lz.setChainlessBalance(0xd2dA8680FfDbe5136EbBb26928dF635D9cB79a0F);
            vm.stopBroadcast();

            for (uint j = 0; j < peers.length; j++) {
                if (i == j) continue;
                vm.startBroadcast();
                lz.addDestination(peers[j].eid);
                lz.setPeer(peers[j].eid, Util.addressToBytes32(peers[j].peer));
                vm.stopBroadcast();
            }
        }
    }
}





