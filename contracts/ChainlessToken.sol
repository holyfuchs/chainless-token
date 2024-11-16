//SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

// import "forge-std/console.sol";

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Origin } from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import { MessagingFee } from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import { OFT } from "@layerzerolabs/oft-evm/contracts/OFT.sol";
import { SendParam, OFTReceipt, MessagingReceipt } from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import { OptionsBuilder } from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";

import { ChainlessBalance } from "./ChainlessBalance.sol";
import { ChainlessTokenMessageCodec, ApproveData } from "./ChainlessTokenMessage.sol";

abstract contract ChainlessToken is OFT {
    using OptionsBuilder for bytes;
    using ChainlessTokenMessageCodec for bytes;

    ChainlessBalance public chainlessBalance;
    uint32[] destinationEids;

    /**
     * @dev Constructor for the ChainlessToken contract.
     * @param _name The name of the ChainlessToken.
     * @param _symbol The symbol of the ChainlessToken.
     * @param _lzEndpoint The LayerZero endpoint address.
     * @param _delegate The delegate capable of making OApp configurations inside of the endpoint.
     */
    constructor(
        string memory _name,
        string memory _symbol,
        address _lzEndpoint,
        address _delegate
    ) OFT(_name, _symbol, _lzEndpoint, _delegate) Ownable(_delegate) {}

    /**
     * @notice Set the address for the linked chainlessBalance
     */
    function setChainlessBalance(address _chainlessBalance) external onlyOwner {
        chainlessBalance = ChainlessBalance(_chainlessBalance);
    }

    /**
     * @notice Adds destination Eids where the balance changes get sent.
     * @dev this also gets added to chainlessBalance.
     *      Code could be changed to only have one array.
     */
    function addDestination(uint32 dstEid) external onlyOwner {
        chainlessBalance.addDestination(dstEid);
        destinationEids.push(dstEid);
    }

    /**
     * @notice Called whenever the balance changes, will broadcast a message to all other chains
     * @param account The account for whom to check
     * @param value The amount of tokens
     */
    function updateBalance(address account, int256 value) internal {
        // MessagingFee[] memory fees = new MessagingFee[](destinationEids.length);
        // for (uint i = 0; i < destinationEids.length; i++) {
        //     fees[i].nativeFee = 200090740;
        // }
        MessagingFee[] memory fees = chainlessBalance.quote(account, value, false);
        // console.log("updateBalance fee", fees[0].nativeFee);
        uint256 nativeFee;
        uint256 tokenFee;
        for (uint256 i = 0; i < fees.length; i++) {
            nativeFee += fees[i].nativeFee;
            tokenFee += fees[i].lzTokenFee;
        }
        chainlessBalance.updateBalance{ value: nativeFee }(account, value, fees);
    }

    /**
     * @notice Gets the value of tokens owned by `account`.
     * @param account The account for whom to check
     * @return value of tokens owned across all chains
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return chainlessBalance.balanceOf(account);
    }

    /**
     * @notice Gets the value of tokens owned by `account` on this chain.
     * @param account The account for whom to check
     * @return value of tokens owned on that specific chain
     */
    function chainBalanceOf(address account) public view returns (uint256) {
        return super.balanceOf(account);
    }

    /**
     * @notice Mints tokens
     * @param account The account for whom to mint
     * @param value amount of tokens to mint
     */
    function mint(address account, uint256 value) external {
        address owner = _msgSender();
        _mint(account, value);
        updateBalance(account, int256(value));
    }

    /**
     * @dev Not implemented! but shouldn't be hard
     */
    function transfer(address to, uint256 value) public virtual override returns (bool) {
        address owner = _msgSender();
        transferFrom(owner, to, value);
        revert("not implemented");
        return true;
    }

    /**
     * @notice Approves tokens, if not enough tokens are on this chain,
     *         it will initiate a bridge of tokens then approve when there
     *         are enough
     * @param spender The spender who is allowed to transfer the tokens
     * @param value amount of tokens to approve
     */
    function approve(address spender, uint256 value) public virtual override returns (bool) {
        address owner = _msgSender();
        uint256 availableValue = chainBalanceOf(owner);
        if (availableValue >= value) {
            _approve(owner, spender, value);
        } else {
            uint256 missingValue = value - availableValue;
            uint32[4] memory eids = chainlessBalance.getChainsWithBalance(owner, int256(missingValue));
            for (uint i = 0; i < 5; i++) {
                if (i == 4) {
                    revert("only 3 hops supported");
                }
                if (eids[i] == 0) {
                    eids[i] = endpoint.eid();
                    break;
                }
            }
            ApproveData memory approveData = ApproveData({ eids: eids, owner: owner, spender: spender, value: value });
            requestTokensAndApprove(approveData, 0, missingValue);
        }
        return true;
    }

    /**
     * @notice Since the logic is in approve this can be used normally
     *         but has to broadcast an update with updateBalance
     * @param from The spender of the tokens
     * @param to The reciever of the tokens
     * @param value amount of tokens
     */
    function transferFrom(address from, address to, uint256 value) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        updateBalance(from, -int256(value));
        updateBalance(to, int256(value));
        return true;
    }

    function requestTokensAndApprove(
        ApproveData memory approveData,
        uint256 bridgeValue,
        uint256 missingValue
    ) internal {
        // console.log("sending from", endpoint.eid());
        // console.log("          to", approveData.eids[0]);
        // console.log("       value", bridgeValue);
        // console.log("     missing", missingValue);
        bytes memory message = ChainlessTokenMessageCodec.encodeMessage(
            approveData,
            bridgeValue, // this doesn't bridge
            missingValue
        );
        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(2_000_000, 0); // yes my code sucks need this much gas
        // MessagingFee memory fee;
        // fee.nativeFee = 2010740;
        MessagingFee memory fee = _quote(
            approveData.eids[0],
            message,
            options,
            false // payInLz
        );

        this.lzSend{ value: fee.nativeFee }(approveData.eids[0], message, options, fee, address(this));
        updateBalance(approveData.owner, -int256(bridgeValue));
    }

    /**
     * @notice sends a message, needed as an external function so it can
     *         be paid by this contract
     */
    function lzSend(
        uint32 dstEid,
        bytes calldata message,
        bytes calldata options,
        MessagingFee memory fee,
        address refundAddress
    ) external payable {
        require(msg.sender == address(this));

        (uint256 amountSentLD, uint256 amountReceivedLD) = _debit(
            message.owner(),
            message.bridgedValue(),
            message.bridgedValue(),
            dstEid
        );

        MessagingReceipt memory msgReceipt = _lzSend(dstEid, message, options, fee, refundAddress);
        OFTReceipt memory oftReceipt = OFTReceipt(amountSentLD, amountReceivedLD);

        emit OFTSent(msgReceipt.guid, dstEid, message.owner(), amountSentLD, amountReceivedLD);
    }

    function _lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _message,
        address /*_executor*/, // @dev unused in the default implementation.
        bytes calldata /*_extraData*/ // @dev unused in the default implementation.
    ) internal virtual override {
        (ApproveData memory approveData, uint256 bridgedValue, uint256 missingValue) = _message.decodeMessage();

        uint256 amountReceivedLD = _credit(approveData.owner, bridgedValue, _origin.srcEid);
        updateBalance(approveData.owner, int256(bridgedValue));

        emit OFTReceived(_guid, _origin.srcEid, approveData.owner, amountReceivedLD);

        // sanity check
        require(endpoint.eid() == approveData.eids[0], "sanity check eid");

        if (approveData.eids[1] == 0) {
            _approve(approveData.owner, approveData.spender, approveData.value);
        } else {
            for (uint i = 0; i < 3; i++) {
                approveData.eids[i] = approveData.eids[i + 1];
            }
            uint256 availableValue = chainBalanceOf(approveData.owner);
            if (availableValue >= missingValue) {
                requestTokensAndApprove(approveData, missingValue, 0);
            } else {
                requestTokensAndApprove(approveData, availableValue, missingValue);
            }
            // console.log("yes not done");
        }
    }

    receive() external payable {
    }
}
