pragma solidity ^0.8.22;

import "../contracts/ChainlessBalance.sol";

// import "forge-std/Test.sol";
import "forge-std/Script.sol";
import {Util} from "./Util.sol";

import {EndpointV2} from "@layerzerolabs/lz-evm-protocol-v2/contracts/EndpointV2.sol";

contract Deploy is Script {
    struct Endpoint {
        string rpcAlias;
        address endpoint;
    }
    Endpoint[] public e;

    function setUp() public {
        e.push(Endpoint("unichain", 0xb8815f3f882614048CbE201a67eF9c6F10fe5035));
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
        peers.push(Peer("unichain", 40333, address(0x0)));
        peers.push(Peer("scroll", 40170, address(0x0)));
        peers.push(Peer("polygon", 40267, address(0x0)));
        peers.push(Peer("zircuit", 40275, address(0x0)));
    }

    function run() public {

        // EndpointV2 e = EndpointV2(0xb8815f3f882614048CbE201a67eF9c6F10fe5035);
        // e.setConfig(_oapp, e.receiveLibrary(), bytes(""));
        // EndpointV2.setConfig(aOApp, sendLibrary, sendConfig);
        // EndpointV2.setConfig(aOApp, receiveLibrary, receiveConfig)

        for (uint i = 0; i < peers.length; i++) {
            ChainlessBalance lz = ChainlessBalance(peers[i].peer);
            vm.createSelectFork(vm.rpcUrl(peers[i].rpcAlias));
            for (uint j = 0; j < peers.length; j++) {
                if (i == j) continue;
                vm.startBroadcast();
                lz.setPeer(peers[j].eid, Util.addressToBytes32(peers[j].peer));
                vm.stopBroadcast();
            }
        }
    }
}
