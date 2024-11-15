// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.22;

import {ApproveData, ChainlessTokenMessageCodec} from "../contracts/ChainlessTokenMessage.sol";

import {Test} from "forge-std/Test.sol";
import "forge-std/console.sol";

contract ChainlessTokenMessageCodecTest is Test {
    using ChainlessTokenMessageCodec for bytes;
    ApproveData a;
    bytes m;

    uint32 constant EID = 1;
    address constant OWNER = address(0x1337);
    address constant SPENDER = address(0xdead);
    uint256 constant VALUE = 696969;
    uint256 constant BRIDGED_VALUE = 1111;
    uint256 constant MISSING_VALUE = 2222;

    function setUp() public {
        uint32[4] memory eids;
        eids[0] = 1;
        a = ApproveData({
            eids: eids,
            owner: OWNER,
            spender: SPENDER,
            value: VALUE
        });
        m = ChainlessTokenMessageCodec.encodeMessage(
            a,
            BRIDGED_VALUE,
            MISSING_VALUE
        );
        console.logBytes(m);
    }

    function test_value() public {
        assertEq(BRIDGED_VALUE, m.bridgedValue());
    }

    function test_owner() public {
        assertEq(OWNER, m.owner());
    }
}
