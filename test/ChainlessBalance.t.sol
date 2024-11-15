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

        assertEq(123, chainlessBalances[0].balanceOf(TEST_ADDR));
        assertEq(123, chainlessBalances[1].balanceOf(TEST_ADDR));
        assertEq(123, chainlessBalances[2].balanceOf(TEST_ADDR));

        chainlessBalances[1].updateBalance{value: nativeFee}(
            TEST_ADDR,
            -23,
            fees
        );
        verifyAllPackets();

        assertEq(100, chainlessBalances[0].balanceOf(TEST_ADDR));
        assertEq(100, chainlessBalances[1].balanceOf(TEST_ADDR));
        assertEq(100, chainlessBalances[2].balanceOf(TEST_ADDR));

        chainlessBalances[2].updateBalance{value: nativeFee}(
            TEST_ADDR,
            1337,
            fees
        );
        verifyAllPackets();

        assertEq(1437, chainlessBalances[0].balanceOf(TEST_ADDR));
        assertEq(1437, chainlessBalances[1].balanceOf(TEST_ADDR));
        assertEq(1437, chainlessBalances[2].balanceOf(TEST_ADDR));
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

}

/**
 * @notice Sets up mock OApp contracts for testing.
 * @param _oappCreationCode The bytecode for creating OApp contracts.
 * @param _startEid The starting endpoint ID for OApp setup.
 * @param _oappNum The number of OApps to set up.
 * @return oapps An array of addresses for the deployed OApps.
 */
