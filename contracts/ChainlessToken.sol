//SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/console.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Origin} from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import {MessagingFee} from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import {OFT, OFTCore} from "@layerzerolabs/oft-evm/contracts/OFT.sol";
import {SendParam, OFTReceipt, MessagingReceipt} from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import {OptionsBuilder} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";
import {IOAppMsgInspector} from "@layerzerolabs/oapp-evm/contracts/oapp/interfaces/IOAppMsgInspector.sol";
// import {IOAppComposer} from "@layerzerolabs/oapp-evm/contracts/oapp/interfaces/IOAppComposer.sol";
import {OFTMsgCodec} from "@layerzerolabs/lz-evm-oft/contracts/oft/libs/OFTMsgCodec.sol";
import {OFTComposeMsgCodec} from "@layerzerolabs/oft-evm/contracts/libs/OFTComposeMsgCodec.sol";
// import { IOFT, SendParam, OFTLimit, OFTReceipt, OFTFeeDetail, MessagingReceipt, MessagingFee } from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";

import {ChainlessBalance} from "./ChainlessBalance.sol";
import {ChainlessTokenMessageCodec, ApproveData} from "./ChainlessTokenMessage.sol";

abstract contract ChainlessToken is OFT {
    using OptionsBuilder for bytes;
    using ChainlessTokenMessageCodec for bytes;
    // using OFTMsgCodec for bytes;
    // using OFTMsgCodec for bytes32;

    // MessagingReceipt lastMsgReceipt;
    // OFTReceipt lastOftReceipt;

    // function LastMsgReceipt() public view returns (MessagingReceipt memory) {
    //     return lastMsgReceipt;
    // }

    // function LastOftReceipt() public view returns (OFTReceipt memory) {
    //     return lastOftReceipt;
    // }
    // TODO
    // this contract should hold ETH to quote and transact himself.

    // uint256 public override totalSupply;
    // string public override name;
    // string public symbol;
    // mapping(address account => uint256) private _balances;
    // mapping(address account => mapping(address spender => uint256)) private _allowances;

    ChainlessBalance public chainlessBalance;
    uint32 public chainlessBalanceServerEid;
    uint32[] destinationEids;
    // mapping(uint32 => address) eidAddress;

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
     */
    function addDestination(uint32 dstEid, address addr) external onlyOwner {
        chainlessBalance.addDestination(dstEid);
        destinationEids.push(dstEid);
        // eidAddress[dstEid] = addr;
    }

    function updateBalance(address account, int256 value) internal {
        // MessagingFee[] memory fees = new MessagingFee[](destinationEids.length);
        // for (uint i = 0; i < destinationEids.length; i++) {
        //     fees[i].nativeFee = 110548;
        // }
        MessagingFee[] memory fees = chainlessBalance.quote(
            account,
            value,
            false
        );
        console.log(fees[0].nativeFee);
        uint256 nativeFee;
        uint256 tokenFee;
        for (uint256 i = 0; i < fees.length; i++) {
            nativeFee += fees[i].nativeFee;
            tokenFee += fees[i].lzTokenFee;
        }
        chainlessBalance.updateBalance{value: nativeFee}(
            account,
            value,
            fees
        );
    }

    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return chainlessBalance.balanceOf(account);
    }

    function chainBalanceOf(address account) public view returns (uint256) {
        return super.balanceOf(account);
    }

    function mint(address account, uint256 value) external onlyOwner {
        address owner = _msgSender();
        _mint(account, value);
        updateBalance(account, int256(value));
    }

    // not sure if this works but who uses it anyways
    function transfer(
        address to,
        uint256 value
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        transferFrom(owner, to, value);
        revert("not implemented");
        return true;
    }

    // function allowance(
    //     address owner,
    //     address spender
    // ) public view virtual override returns (uint256) {
    //     // return 1;
    //     return _allowance(owner, spender);
    //     // return oft.allowance(owner, spender);
    // }

    function approve(
        address spender,
        uint256 value
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        uint256 availableValue = chainBalanceOf(owner);
        if (availableValue >= value) {
            _approve(owner, spender, value);
        } else {
            uint256 missingValue = value - availableValue;
            uint32[4] memory eids = chainlessBalance.getChainsWithBalance(
                owner,
                int256(missingValue)
            );
            console.log(eids[0], eids[1], eids[2], eids[3]);
            for (uint i = 0; i < 5; i++) {
                if (i == 4) {
                    revert ("only 3 hops supported");
                }
                if (eids[i] == 0) {
                    eids[i] = endpoint.eid();
                    break;
                }
            }
            ApproveData memory approveData = ApproveData({
                eids: eids,
                owner: owner,
                spender: spender,
                value: value
            });
            requestTokensAndApprove(approveData, 0, missingValue);
        }
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public virtual override returns (bool) {
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
    ) public {
        // console.log("sending from", endpoint.eid());
        // console.log("          to", approveData.eids[0]);
        // console.log("       value", bridgeValue);
        // console.log("     missing", missingValue);
        bytes memory message = ChainlessTokenMessageCodec.encodeMessage(
            approveData,
            bridgeValue, // this doesn't bridge
            missingValue
        );
        bytes memory options = OptionsBuilder
            .newOptions()
            .addExecutorLzReceiveOption(2_000_000, 0); // yes my code sucks need this much gas
        // MessagingFee memory fee;
        // fee.nativeFee = 2010740;
        MessagingFee memory fee = _quote(
            approveData.eids[0],
            message,
            options,
            false // payInLz
        );

        this.lzSend{value: fee.nativeFee}(
            approveData.eids[0],
            message,
            options,
            fee,
            address(this)
        );
        updateBalance(approveData.owner, -int256(bridgeValue));
    }

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

        MessagingReceipt memory msgReceipt = _lzSend(
            dstEid,
            message,
            options,
            fee,
            refundAddress
        );
        OFTReceipt memory oftReceipt = OFTReceipt(
            amountSentLD,
            amountReceivedLD
        );

        emit OFTSent(
            msgReceipt.guid,
            dstEid,
            message.owner(),
            amountSentLD,
            amountReceivedLD
        );
    }

    function _lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _message,
        address /*_executor*/, // @dev unused in the default implementation.
        bytes calldata /*_extraData*/ // @dev unused in the default implementation.
    ) internal virtual override {
        (
            ApproveData memory approveData,
            uint256 bridgedValue,
            uint256 missingValue
        ) = _message.decodeMessage();

        uint256 amountReceivedLD = _credit(
            approveData.owner,
            bridgedValue,
            _origin.srcEid
        );
        updateBalance(approveData.owner, int256(bridgedValue));
        
        emit OFTReceived(_guid, _origin.srcEid, approveData.owner, amountReceivedLD);

        // sanity check
        require(endpoint.eid() == approveData.eids[0], "sanity check eid");

        if (approveData.eids[1] == 0) {
            console.log("WIN!!!");
            _approve(approveData.owner, approveData.spender, approveData.value);   
        } else {
            for (uint i = 0; i < 3; i++) {
                approveData.eids[i] = approveData.eids[i+1];
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

    // function addressToBytes32(address _addr) internal pure returns (bytes32) {
    //     return bytes32(uint256(uint160(_addr)));
    // }

    // function send(
    //     SendParam calldata _sendParam,
    //     MessagingFee calldata _fee,
    //     address _refundAddress,
    //     address account
    // )
    //     public
    //     payable
    //     virtual
    //     returns (
    //         MessagingReceipt memory msgReceipt,
    //         OFTReceipt memory oftReceipt
    //     )
    // {
    //     require(msg.sender == address(this));
    //     // @dev Applies the token transfers regarding this send() operation.
    //     // - amountSentLD is the amount in local decimals that was ACTUALLY sent/debited from the sender.
    //     // - amountReceivedLD is the amount in local decimals that will be received/credited to the recipient on the remote OFT instance.
    //     (uint256 amountSentLD, uint256 amountReceivedLD) = _debit(
    //         account,
    //         _sendParam.amountLD,
    //         _sendParam.minAmountLD,
    //         _sendParam.dstEid
    //     );
    //     // @dev Builds the options and OFT message to quote in the endpoint.
    //     (bytes memory message, bytes memory options) = _buildMsgAndOptions(
    //         _sendParam,
    //         amountReceivedLD
    //     );
    //     // @dev Sends the message to the LayerZero endpoint and returns the LayerZero msg receipt.
    //     msgReceipt = _lzSend(
    //         _sendParam.dstEid,
    //         message,
    //         options,
    //         _fee,
    //         _refundAddress
    //     );
    //     // @dev Formulate the OFT receipt.
    //     oftReceipt = OFTReceipt(amountSentLD, amountReceivedLD);

    //     emit OFTSent(
    //         msgReceipt.guid,
    //         _sendParam.dstEid,
    //         account,
    //         amountSentLD,
    //         amountReceivedLD
    //     );
    // }
}
