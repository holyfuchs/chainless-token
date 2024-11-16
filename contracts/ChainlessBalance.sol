//SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

// import "forge-std/console.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { OApp, Origin, MessagingFee } from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import { OptionsBuilder } from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";

contract ChainlessBalance is OApp {
    using OptionsBuilder for bytes;

    // account => balance
    mapping(address => int256) private balances;

    /// @dev if the lzRead stuff works no longer need this
    /// eid => account => balance
    mapping(uint32 => mapping(address => int256)) public chainBalances;

    /// @dev token has permission to update balances
    address token;

    /// @dev where to push updated balances
    uint32[] destinationEids;

    event BalanceUpdateSent(address indexed account, int256 amount);
    event BalanceUpdateRecieve(address indexed account, uint32 srcEid, int256 amount);

    constructor(address _endpoint, address _owner) OApp(_endpoint, _owner) Ownable(_owner) {}

    modifier onlyToken() {
        require(msg.sender == token, "not token");
        _;
    }

    function setToken(address _token) external onlyOwner {
        token = _token;
    }

    /**
     * @notice Adds destination Eids where the balance changes get sent.
     * @param dstEid The destination eid to add
     */
    function addDestination(uint32 dstEid) public virtual onlyToken {
        destinationEids.push(dstEid);
    }

    /**
     * @notice Gets the value of tokens owned by `account`.
     * @param account The account for whom to check
     * @return value of tokens owned across all chains
     */
    function balanceOf(address account) public view returns (uint256) {
        return uint256(balances[account]);
    }

    /**
     * @notice Gets the value of tokens owned by `account` on an eid.
     * @param account The account for whom to check
     * @param eid The eid on which to check
     * @return value of tokens owned on that specific chain
     */
    function chainBalanceOf(address account, uint32 eid) public view returns (int256) {
        return int256(chainBalances[eid][account]);
    }

    /**
     * @notice Called whenever the balance changes, will broadcast a message to all other chains
     * @param account The account for whom to check
     * @param amount The amount of tokens
     * @param fees The fees requested by quote
     */
    function updateBalance(
        address account,
        int256 amount,
        MessagingFee[] calldata fees
    ) public payable virtual onlyToken {
        require(fees.length == destinationEids.length);
        _updateBalance(account, amount, endpoint.eid());
        bytes memory payload = abi.encode(account, amount);
        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(80000, 0); // 50k to low

        for (uint32 i = 0; i < destinationEids.length; i++) {
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

    /**
     * @notice Gets eids where sum(chainBalanceOf) >= missingBalance tokens.
     * @param account the account for whom to get the balance
     * @param missingBalance the missing balance (usually balance - tokens already owned on src chain)
     * @return eids array of eids
     * @dev very unoptimised can handle 3 other chains maximum
     */
    function getChainsWithBalance(address account, int256 missingBalance) public view returns (uint32[4] memory) {
        uint32[4] memory eids; // not nice but not sure how else to do it
        uint256 eidsSize = 0;
        for (uint i = 0; i < destinationEids.length; i++) {
            uint32 eid = destinationEids[i];
            int256 chainBalance = chainBalances[eid][account];
            if (chainBalance != 0) {
                missingBalance -= chainBalance;
                eids[eidsSize] = eid;
                eidsSize += 1;
                if (missingBalance <= 0) {
                    break;
                }
            }
            if (eidsSize >= 4) {
                revert("to many chains to get balance from");
            }
        }
        require(missingBalance <= 0, "still missing balance"); // sanity check
        return eids;
    }

    function _lzReceive(
        Origin calldata origin,
        bytes32 _guid,
        bytes calldata payload,
        address, // Executor address as specified by the OApp.
        bytes calldata // Any extra data or options to trigger on receipt.
    ) internal virtual override {
        (address account, int256 amount) = abi.decode(payload, (address, int256));
        _updateBalance(account, amount, origin.srcEid);
    }

    function _updateBalance(address account, int256 amount, uint32 eid) internal {
        chainBalances[eid][account] += amount;
        balances[account] += amount;
        emit BalanceUpdateRecieve(account, eid, amount);
    }

    /**
     * @notice Quote for the updatebalance. Fees have to be summed up to get the native value needed to be sent.
     * @param account The account (probably doesn't matter for the quote)
     * @param amount The amount of tokens (probably doesn't matter for the quote)
     * @param payInLzToken bool if fees should be paid in lz tokens
     * @return fees array of fees
     */
    function quote(address account, int256 amount, bool payInLzToken) external view returns (MessagingFee[] memory) {
        bytes memory payload = abi.encode(account, amount);
        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(80000, 0); // 50k to low
        MessagingFee[] memory fees = new MessagingFee[](destinationEids.length);
        for (uint256 i = 0; i < destinationEids.length; i++) {
            MessagingFee memory fee = _quote(destinationEids[i], payload, options, payInLzToken);
            fees[i] = fee;
        }
        return fees;
    }

    /**
     * @notice Not quite sure why its needed but otherwise sending reverts
     */
    function _payNative(uint256 _nativeFee) internal override returns (uint256 nativeFee) {
        if (msg.value < _nativeFee) revert NotEnoughNative(msg.value);
        return _nativeFee;
    }
}
