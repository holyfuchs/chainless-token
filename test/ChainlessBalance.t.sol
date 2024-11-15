// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.22;

import {Packet} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ISendLib.sol";
import {OptionsBuilder} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";
import {MessagingFee} from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import {MessagingReceipt} from "@layerzerolabs/oapp-evm/contracts/oapp/OAppSender.sol";
import {TestHelperOz5} from "@layerzerolabs/test-devtools-evm-foundry/contracts/TestHelperOz5.sol";
import {EndpointV2Mock} from "@layerzerolabs/test-devtools-evm-foundry/contracts/mocks/EndpointV2Mock.sol";

import {ChainlessBalance} from "../contracts/ChainlessBalance.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "forge-std/console.sol";

contract ChainlessBalanceTest is TestHelperOz5 {
    using OptionsBuilder for bytes;

    uint8 constant ENDPOINT_COUNT = 3;

    uint16[] destinationEids;
    ChainlessBalance[] chainlessBalances;

    function setUp() public virtual override {
        super.setUp();

        setUpEndpoints(ENDPOINT_COUNT, LibraryType.SimpleMessageLib);

        address[] memory oapps = new address[](ENDPOINT_COUNT);
        for (uint32 i = 0; i < ENDPOINT_COUNT; i++) {
            ChainlessBalance cb = new ChainlessBalance(
                    address(endpoints[i + 1]),
                    address(this)
            );
            oapps[i] = address(cb);
        }
        wireOApps(oapps);

        // address[] memory sender = setupOApps(
        //     type(ChainlessBalance).creationCode,
        //     1,
        //     ENDPOINT_COUNT
        // );

        for (uint i = 0; i < ENDPOINT_COUNT; i++) {
            chainlessBalances.push(ChainlessBalance(payable(oapps[i])));
            destinationEids.push(uint16(i + 1));
        }

        for (uint256 i = 0; i < ENDPOINT_COUNT; i++) {
            chainlessBalances[i].setToken(address(this));
            for (uint256 j = 0; j < ENDPOINT_COUNT; j++) {
                if (i != j) {
                    chainlessBalances[i].addDestination(destinationEids[j]);
                }
            }
        }
    }

    function verifyAllPackets() internal {
        for (uint256 i = 0; i < ENDPOINT_COUNT; i++) {
            verifyPackets(
                destinationEids[i],
                addressToBytes32(address(chainlessBalances[i]))
            );
        }
    }

    function test_balanceUpdate() public {
        address TEST_ADDR = address(0x1337);

        MessagingFee[] memory fees = chainlessBalances[0].quote(
            TEST_ADDR,
            123,
            false
        );
        uint256 nativeFee;
        uint256 tokenFee;
        for (uint256 i = 0; i < fees.length; i++) {
            nativeFee += fees[i].nativeFee;
            tokenFee += fees[i].lzTokenFee;
        }
        console.log("total native fee", nativeFee);
        console.log("total token  fee", tokenFee);

        chainlessBalances[0].updateBalance{value: nativeFee}(
            TEST_ADDR,
            123,
            fees
        );
        verifyAllPackets();

        for (uint256 i = 0; i < chainlessBalances.length; i++) {
            assertEq(123, chainlessBalances[i].balanceOf(TEST_ADDR));

            assertEq(123, chainlessBalances[i].chainBalanceOf(TEST_ADDR, 1));
            assertEq(0, chainlessBalances[i].chainBalanceOf(TEST_ADDR, 2));
            assertEq(0, chainlessBalances[i].chainBalanceOf(TEST_ADDR, 3));
        }

        chainlessBalances[1].updateBalance{value: nativeFee}(
            TEST_ADDR,
            -23,
            fees
        );
        verifyAllPackets();

        for (uint256 i = 0; i < chainlessBalances.length; i++) {
            assertEq(100, chainlessBalances[i].balanceOf(TEST_ADDR));

            assertEq(123, chainlessBalances[i].chainBalanceOf(TEST_ADDR, 1));
            assertEq(-23, chainlessBalances[i].chainBalanceOf(TEST_ADDR, 2));
            assertEq(0, chainlessBalances[i].chainBalanceOf(TEST_ADDR, 3));
        }
    }

    function mintStuff(address TEST_ADDR) internal {
        MessagingFee[] memory fees = chainlessBalances[0].quote(
            TEST_ADDR,
            100,
            false
        );
        uint256 nativeFee;
        uint256 tokenFee;
        for (uint256 i = 0; i < fees.length; i++) {
            nativeFee += fees[i].nativeFee;
            tokenFee += fees[i].lzTokenFee;
        }

        for (uint256 i = 0; i < 3; i++) {
            chainlessBalances[i].updateBalance{value: nativeFee}(
                TEST_ADDR,
                100,
                fees
            );
        }
        verifyAllPackets();

        for (uint256 i = 0; i < chainlessBalances.length; i++) {
            assertEq(300, chainlessBalances[i].balanceOf(TEST_ADDR));
        }
    }

    function test_ChainsWithBalance() public {
        address TEST_ADDR = address(0x1337);
        mintStuff(TEST_ADDR);

        ChainlessBalance cb = chainlessBalances[0];

        assertEq(100, cb.chainBalances(1, TEST_ADDR));
        assertEq(100, cb.chainBalances(2, TEST_ADDR));
        assertEq(100, cb.chainBalances(3, TEST_ADDR));

        {
            uint32[4] memory eids = cb.getChainsWithBalance(TEST_ADDR, 200);
            assertEq(2, eids[0]);
            assertEq(3, eids[1]);
            assertEq(0, eids[2]);
        }

        {
            uint32[4] memory eids = cb.getChainsWithBalance(TEST_ADDR, 101);
            assertEq(2, eids[0]);
            assertEq(3, eids[1]);
            assertEq(0, eids[2]);
        }

        {
            uint32[4] memory eids = cb.getChainsWithBalance(TEST_ADDR, 100);
            assertEq(2, eids[0]);
            assertEq(0, eids[1]);
        }

        cb = chainlessBalances[1];

        {
            uint32[4] memory eids = cb.getChainsWithBalance(TEST_ADDR, 200);
            assertEq(1, eids[0]);
            assertEq(3, eids[1]);
            assertEq(0, eids[2]);
        }

        cb = chainlessBalances[2];

        {
            uint32[4] memory eids = cb.getChainsWithBalance(TEST_ADDR, 200);
            assertEq(1, eids[0]);
            assertEq(2, eids[1]);
            assertEq(0, eids[2]);
        }
    }
}
