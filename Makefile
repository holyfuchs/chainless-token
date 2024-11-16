RPC_SCROLL="https://sepolia-rpc.scroll.io"
RPC_POLYGON="https://rpc.ankr.com/polygon_mumbai"

LOCAL_RPC="http://localhost:8545"
RPC_SEPOLIA="https://sepolia.drpc.org"
POLYGON_AMOY_RPC="https://rpc-amoy.polygon.technology/"
MORPH_HOLESKY_RPC="https://rpc-quicknode-holesky.morphl2.io/"
FLOW_RPC="https://testnet.evm.nodes.onflow.org"
SKALE_RPC="https://testnet.skalenodes.com/v1/giant-half-dual-testnet"
ZIRCUIT_RPC="https://zircuit1-testnet.liquify.com"

include .env
export

deploy-balance:
	forge script script/ChainlessBalance.s.sol:Deploy --broadcast --private-key $(PRIVATE_KEY) -vvvv --ffi
connect-balance:
	forge script script/ChainlessBalance.s.sol:Connect --private-key $(PRIVATE_KEY) -vvvv --ffi	

teststuff:
	echo $(ZIRCUIT_API_KEY) 

# verify-zircuit:
# 	forge verify-contract \
# 	0x1d9F50D64511770695284D98E882Fb4B436191ad \
# 	contracts/ChainlessBalance.sol:ChainlessBalance \
# 	--verifier-url https://explorer.zircuit.com/api/contractVerifyHardhat \
# 	--etherscan-api-key $(ZIRCUIT_API_KEY) \
# 	--rpc-url $(ZIRCUIT_RPC) \
# 	--guess-constructor-args \
# 	--chain zircuit-testnet
# 	--watch

verify-unichain:
	forge verify-contract \
	--rpc-url https://sepolia.unichain.org \
	--verifier blockscout \
	--verifier-url 'https://unichain-sepolia.blockscout.com/api/' \
	0x1d9F50D64511770695284D98E882Fb4B436191ad \
	contracts/ChainlessBalance.sol:ChainlessBalance

# verify-zircuit:
# 	forge verify-contract \
# 	0x7b2E16f2a8cAf323AD4828BA5D8F6C36a679d2e2 \
# 	src/BridgeSelector.sol:BridgeSelector \
# 	--verifier-url https://explorer.zircuit.com/api/contractVerifyHardhat \
# 	-e $(ETHERSCAN_API_KEY) \
# 	--rpc-url https://sepolia.drpc.org \
# 	--guess-constructor-args \
# 	--chain sepolia \
# 	--watch

# verify-zircuit:
# 	forge verify-contract \
# 	--verifier-url https://explorer.zircuit.com/api/contractVerifyHardhat \
# 	0x1d9F50D64511770695284D98E882Fb4B436191ad \
# 	<source-file>:<contract-name> --root . --etherscan-api-key <ZIRCUIT_API_KEY>

