//SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

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
