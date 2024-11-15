//SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import "forge-std/console.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {OApp, Origin, MessagingFee} from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import {OptionsBuilder} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";

contract ChainlessBalance is OApp {
    using OptionsBuilder for bytes;

    mapping(address => int256) private balances;
    address token;
    uint32[] destinationEids;

    event BalanceUpdateSent(address indexed account,int256 amount);
    event BalanceUpdateRecieve(
        address indexed account,
        uint32 srcEid,
        int256 amount
    );

    constructor(
        address _endpoint,
        address _owner
    ) OApp(_endpoint, _owner) Ownable(_owner) {}

    modifier onlyToken() {
        require(msg.sender == token, "not token");
        _;
    }
    
    function setToken(address _token) external onlyOwner {
        token = _token;
    }

    function addDestination(uint32 dstEid) public virtual onlyToken {
        destinationEids.push(dstEid);
    }

    function balanceOf(address account) public view returns (uint256) {
        return uint256(balances[account]);
    }

    function updateBalance(
        address account,
        int256 amount,
        MessagingFee[] calldata fees
    ) public payable virtual onlyToken {
        require(fees.length == destinationEids.length);
        bytes memory payload = abi.encode(account, amount);
        balances[account] += amount;

        bytes memory options = OptionsBuilder
            .newOptions()
            .addExecutorLzReceiveOption(100000, 0);

        for (uint32 i; i < destinationEids.length; i++) {
            _lzSend(
                destinationEids[i],
                payload,
                options,
                // Fee in native gas and ZRO token.
                // (uint128 _gas, uint128 _value)
                MessagingFee(fees[i].nativeFee, fees[i].lzTokenFee),
                // Refund address in case of failed source message.
                payable(msg.sender)
            );
        }
        emit BalanceUpdateSent(account, amount);
    }

    function _lzReceive(
        Origin calldata origin,
        bytes32 _guid,
        bytes calldata payload,
        address, // Executor address as specified by the OApp.
        bytes calldata // Any extra data or options to trigger on receipt.
    ) internal virtual override{
        (address account, int256 amount) = abi.decode(
            payload,
            (address, int256)
        );
        balances[account] += amount;
        emit BalanceUpdateRecieve(account, origin.srcEid, amount);
    }

    function quote(
        address account,
        int256 amount,
        bool payInLzToken
    ) external view returns (MessagingFee[] memory) {
        bytes memory payload = abi.encode(account, amount);
        bytes memory options = OptionsBuilder
            .newOptions()
            .addExecutorLzReceiveOption(100000, 0);
        MessagingFee[] memory fees = new MessagingFee[](destinationEids.length);
        for (uint256 i = 0; i < destinationEids.length; i++) {
            MessagingFee memory fee = _quote(
                destinationEids[i],
                payload,
                options,
                payInLzToken
            );
            fees[i] = fee;
        }
        return fees;
    }

    function _payNative(
        uint256 _nativeFee
    ) internal override returns (uint256 nativeFee) {
        if (msg.value < _nativeFee) revert NotEnoughNative(msg.value);
        return _nativeFee;
    }
}
