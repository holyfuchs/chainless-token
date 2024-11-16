pragma solidity ^0.8.22;

import "../contracts/ChainlessBalance.sol";

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
        e.push(Endpoint("scroll", 0x6EDCE65403992e310A62460808c4b910D972f10f));
        e.push(Endpoint("polygon", 0x6EDCE65403992e310A62460808c4b910D972f10f));
        e.push(Endpoint("zircuit", 0x6EDCE65403992e310A62460808c4b910D972f10f));
    }

    function run() public {
        for (uint i = 0; i < e.length; i++) {
            string memory rpcAlias = e[i].rpcAlias;
            vm.createSelectFork(vm.rpcUrl(rpcAlias));
            vm.startBroadcast();
            ChainlessBalance cb = new ChainlessBalance(e[i].endpoint, msg.sender);
            vm.stopBroadcast();
            console.log(string.concat("deployed on: ", rpcAlias, " at: ", vm.toString(address(cb))));
        }
    }
}

contract Connect is Script {
    struct Peer {
        string rpcAlias;
        uint32 eid;
        address peer;
    }
    Peer[] public peers;

    function setUp() public {
        // peers.push(Peer("sepolia", 40333, 0x7570adcf326406ef55C03e81d568EE1836E9A0e2));
        peers.push(Peer("scroll", 40170, 0x114F9aFB1dce419E06d6709CfA87954378cf492e));
        peers.push(Peer("polygon", 40267, 0x114F9aFB1dce419E06d6709CfA87954378cf492e));
        peers.push(Peer("zircuit", 40275, 0x114F9aFB1dce419E06d6709CfA87954378cf492e));
    }

    // function run() public {
    //     uint i = 2;
    //     vm.createSelectFork(vm.rpcUrl(peers[i].rpcAlias));
    //     ChainlessBalance lz = ChainlessBalance(peers[i].peer);

    //     vm.startBroadcast();
    //     // lz.setToken(0x7CFA3f1199f2A48EAFb69b3a0D80234b98516110);
    //     lz.setToken(0x5EC52789EE47241B40bcf758ae913f1AD4F783D6);
    //     vm.stopBroadcast();
    // }

    function run() public {
        for (uint i = 0; i < peers.length; i++) {
            vm.createSelectFork(vm.rpcUrl(peers[i].rpcAlias));
            ChainlessBalance lz = ChainlessBalance(peers[i].peer);

            vm.startBroadcast();
            lz.setToken(0xA8FF03a3aF16A07e505Fa7b5c1e3E2726D9787A3);
            vm.stopBroadcast();

            for (uint j = 0; j < peers.length; j++) {
                if (i == j) continue;
                vm.startBroadcast();
                lz.setPeer(peers[j].eid, Util.addressToBytes32(peers[j].peer));
                vm.stopBroadcast();
            }
        }
    }
}
