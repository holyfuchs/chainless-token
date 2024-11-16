// // SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.22;

import {Packet} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ISendLib.sol";
import {OptionsBuilder} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";
import {MessagingFee} from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import {MessagingReceipt} from "@layerzerolabs/oapp-evm/contracts/oapp/OAppSender.sol";

import {TestHelperOz5} from "@layerzerolabs/test-devtools-evm-foundry/contracts/TestHelperOz5.sol";

import {OFTComposeMsgCodec} from "@layerzerolabs/oft-evm/contracts/libs/OFTComposeMsgCodec.sol";
import {SendParam, OFTReceipt} from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";

import {ChainlessUSD} from "../contracts/ChainlessUSD.sol";
import {ChainlessToken} from "../contracts/ChainlessToken.sol";
import {ChainlessBalance} from "../contracts/ChainlessBalance.sol";

import "forge-std/console.sol";

contract ChainlessTokenTest is TestHelperOz5 {
    using OptionsBuilder for bytes;

    uint8 constant TOKEN_COUNT = 3;

    uint16[] destinationEids;
    ChainlessUSD[] tokens;

    function setUp() public virtual override {
        super.setUp();

        setUpEndpoints(TOKEN_COUNT, LibraryType.UltraLightNode);

        address[] memory chainlessBalances = setupOApps(
            type(ChainlessBalance).creationCode,
            1,
            TOKEN_COUNT
        );

        address[] memory ofts = new address[](TOKEN_COUNT);
        for (uint8 eid = 1; eid < TOKEN_COUNT + 1; eid++) {
            ChainlessUSD oft = new ChainlessUSD(
                "USD Chainless",
                "USDCL",
                address(endpoints[eid]),
                address(this)
            );
            ofts[eid - 1] = address(oft);
            tokens.push(oft);
        }
        wireOApps(ofts);

        for (uint256 i = 0; i < ofts.length; i++) {
            vm.deal(address(tokens[i]), 1 ether);
            tokens[i].setChainlessBalance(chainlessBalances[i]);
            ChainlessBalance(chainlessBalances[i]).setToken(address(tokens[i]));
            for (uint256 j = 0; j < TOKEN_COUNT; j++) {
                if (i != j) {
                    tokens[i].addDestination(uint32(j + 1));
                }
            }
        }
    }

    function verifyAllPackets() internal {
        for (uint256 i = 0; i < tokens.length; i++) {
            verifyPackets(
                uint32(i + 1),
                addressToBytes32(address(tokens[i].chainlessBalance()))
            );
            verifyPackets(uint32(i + 1), addressToBytes32(address(tokens[i])));
        }
    }

    function assertAllBalances(address account, uint256 balance) internal {
        for (uint256 i = 0; i < tokens.length; i++) {
            assertEq(balance, tokens[0].balanceOf(account));
        }
    }

    function test_mint() public {
        vm.deal(address(tokens[0]), 1 ether);
        vm.deal(address(tokens[1]), 1 ether);

        tokens[0].mint(address(0x1337), 1337);
        verifyAllPackets();
        assertAllBalances(address(0x1337), 1337);

        tokens[1].mint(address(0x1337), 10);
        verifyAllPackets();
        assertAllBalances(address(0x1337), 1347);

        assertEq(1337, tokens[0].chainBalanceOf(address(0x1337)));
        assertEq(10, tokens[1].chainBalanceOf(address(0x1337)));
        assertEq(0, tokens[2].chainBalanceOf(address(0x1337)));
    }

    function test_transferFromWithBalance() public {
        vm.deal(address(tokens[0]), 1 ether);

        tokens[0].mint(address(0x1337), 100);

        vm.startPrank(address(0x1337));
        tokens[0].approve(address(this), 10);
        vm.stopPrank();
        tokens[0].transferFrom(address(0x1337), address(0xdead), 10);
        verifyAllPackets();
        assertAllBalances(address(0x1337), 90);
        assertAllBalances(address(0xdead), 10);
    }

    function test_transferFromWithoutBalance() public {
        vm.deal(address(tokens[0]), 1 ether);
        vm.deal(address(tokens[1]), 1 ether);
        vm.deal(address(tokens[2]), 1 ether);

        tokens[0].mint(address(0x1337), 10 ether);
        tokens[1].mint(address(0x1337), 10 ether);
        verifyAllPackets();

        vm.expectRevert();
        tokens[0].transferFrom(address(0x1337), address(this), 11 ether); 

        vm.startPrank(address(0x1337));
        tokens[0].approve(address(this), 11 ether);
        vm.stopPrank();

        verifyAllPackets();
        verifyAllPackets();  // need to verify 2 times!

        assertAllBalances(address(0x1337), 20 ether);
        assertEq(11 ether, tokens[0].chainBalanceOf(address(0x1337)));
        assertEq(9 ether, tokens[1].chainBalanceOf(address(0x1337)));

        assertEq(11 ether, tokens[0].chainlessBalance().chainBalanceOf(address(0x1337), 1), "0");
        assertEq(9 ether, tokens[1].chainlessBalance().chainBalanceOf(address(0x1337), 2), "1");
        assertEq(11 ether, tokens[0].chainlessBalance().chainBalanceOf(address(0x1337), 1), "2");
        assertEq(9 ether, tokens[1].chainlessBalance().chainBalanceOf(address(0x1337), 2), "3");

        tokens[0].transferFrom(address(0x1337), address(this), 11 ether);
    }

    function test_transferFromMultiHop() public {
        tokens[2].mint(address(0x1337), 10 ether);
        tokens[1].mint(address(0x1337), 10 ether);
        tokens[0].mint(address(0x1337), 10 ether);
        verifyAllPackets();

        vm.prank(address(0x1337));
        tokens[2].approve(address(this), 30 ether);
        
        verifyAllPackets(); // token[0] tells token[1] to send money to token[2] 
        verifyAllPackets(); // token[1] sends money to token[2]
        verifyAllPackets(); // token[2] sends money to token[0]

        assertAllBalances(address(0x1337), 30 ether);
        assertEq(0 ether, tokens[0].chainBalanceOf(address(0x1337)), "0");
        assertEq(0 ether, tokens[1].chainBalanceOf(address(0x1337)), "1");
        assertEq(30 ether, tokens[2].chainBalanceOf(address(0x1337)), "2");

        tokens[2].transferFrom(address(0x1337), address(this), 30 ether);
    }
}
