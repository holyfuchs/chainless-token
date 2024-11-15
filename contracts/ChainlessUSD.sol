//SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/console.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MessagingFee} from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import {OFT} from "@layerzerolabs/oft-evm/contracts/OFT.sol";

import {ChainlessToken} from "./ChainlessToken.sol";

contract ChainlessUSD is ChainlessToken {
    
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
    )  ChainlessToken(_name, _symbol, _lzEndpoint, _delegate) {}

}
