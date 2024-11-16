// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

struct ApproveData{
    uint32[4] eids; // could store this in a single uint256 for encoding
    address owner;
    address spender;
    uint256 value;
}

library ChainlessTokenMessageCodec {
    uint32 private constant OWNER_OFFSET = 4 * 32;
    uint32 private constant MISSING_VALUE_OFFSET = 7 * 32;

    function encodeMessage(
        ApproveData memory _approve,
        uint256 _bridgedValue,
        uint256 _missingValue
    ) public view returns (bytes memory message) {
        message = abi.encode(_approve, _bridgedValue, _missingValue);
    }

    function bridgedValue(bytes calldata message) public pure returns (uint256) {
        return uint256(bytes32(message[MISSING_VALUE_OFFSET:]));
    }

    function owner(bytes calldata message) public pure returns (address) {
        return bytes32ToAddress(bytes32(message[OWNER_OFFSET:]));
    }

    function decodeMessage(
        bytes calldata message
    )
        public
        pure
        returns (
            ApproveData memory approve,
            uint256 _bridgedValue,
            uint256 missingValue
        )
    {
        // ApproveData memory approve;
        // uint256 value;
        // uint256 missingValue;

        (approve, _bridgedValue, missingValue) = abi.decode(
            message,
            (ApproveData, uint256, uint256)
        );
    }

    /**
     * @dev Converts bytes32 to an address.
     * @param _b The bytes32 value to convert.
     * @return The address representation of bytes32.
     */
    function bytes32ToAddress(bytes32 _b) internal pure returns (address) {
        return address(uint160(uint256(_b)));
    }
}
