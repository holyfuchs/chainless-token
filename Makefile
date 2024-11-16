# RPC_UNICHAIN="https://sepolia.unichain.org"
# RPC_SCROLL="https://sepolia-rpc.scroll.io"
RPC_POLYGON="https://rpc-amoy.polygon.technology"
RPC_ZIRCUIT="https://zircuit1-testnet.liquify.com"

include .env
export

deploy-balance:
	forge script script/ChainlessBalance.s.sol:Deploy --broadcast --private-key $(PRIVATE_KEY) -vvvv --ffi
connect-balance:
	forge script script/ChainlessBalance.s.sol:Connect --broadcast --private-key $(PRIVATE_KEY) -vvvv --ffi	


# multichain deployment not supported make sure to set the correct endpoint id!!
deploy-token:
	forge script script/ChainlessToken.s.sol:Deploy --fork-url $(RPC_ZIRCUIT) --broadcast --private-key $(PRIVATE_KEY) -vvvv
connect-token:
	forge script script/ChainlessToken.s.sol:Connect --broadcast --private-key $(PRIVATE_KEY) -vvvv --ffi
#--with-gas-price 3058840274 --legacy

fund-zircuit:
	cast send 0x753da027758f33f9dF35b8529Fa9b2e78664DfE5 --value 50000000000000000 --private-key $(PRIVATE_KEY) --rpc-url $(RPC_ZIRCUIT)
fund-polygon:
	cast send 0x753da027758f33f9dF35b8529Fa9b2e78664DfE5 --value 20000000000000000 --private-key $(PRIVATE_KEY) --rpc-url $(RPC_POLYGON)

demo-mint-zircuit:
	@forge script script/Demo.s.sol:MintZircuit --broadcast --private-key $(PRIVATE_KEY) -vvvv --ffi
demo-get-balance-polygon-amoy:
	@forge script script/Demo.s.sol:GetBalancePolygonAmoy --private-key $(PRIVATE_KEY) -vvvv --ffi
demo-get-balance-zircuit:
	@forge script script/Demo.s.sol:GetBalanceZircuit --private-key $(PRIVATE_KEY) -vvvv --ffi
demo-approve-polygon-amoy:
	@forge script script/Demo.s.sol:ApprovePolygonAmoy --broadcast --private-key $(PRIVATE_KEY_USER) -vvvv --ffi
demo-get-allowance:
	@forge script script/Demo.s.sol:GetAllowance --private-key $(PRIVATE_KEY_USER) -vvvv --ffi

# test-balance-zircuit:
# 	forge test --match-test "test_balance" -vv --fork-url $(RPC_ZIRCUIT)
# test-balance-polygon:
# 	forge test --match-test "test_balance" -vv --fork-url $(RPC_POLYGON)
# just verification stuff below here

verify-balance-unichain:
	forge verify-contract \
	--rpc-url $(RPC_UNICHAIN) \
	--verifier blockscout \
	--verifier-url 'https://unichain-sepolia.blockscout.com/api/' \
	0x8d79f26c1b29f2833D6B36b3e902c9c537450568 \
	contracts/ChainlessBalance.sol:ChainlessBalance

verify-balance-scroll:
	forge verify-contract \
	--rpc-url $(RPC_SCROLL) \
	--verifier blockscout \
	--verifier-url 'https://scroll-sepolia.blockscout.com/api/' \
	0xaC45aaab89741702a9A0083E28fbcfe28ffE7a96 \
	contracts/ChainlessBalance.sol:ChainlessBalance \
	--watch

verify-balance-polygon:
	forge verify-contract \
	--rpc-url $(RPC_POLYGON) \
	--verifier-url 'https://api-amoy.polygonscan.com/api' \
	-e $(POLYGON_API_KEY) \
	0xd2dA8680FfDbe5136EbBb26928dF635D9cB79a0F \
	contracts/ChainlessBalance.sol:ChainlessBalance \
	--guess-constructor-args \
	--watch

# Details: `Fail - Unable to verify. Please check for missing Library or invalid name (i.e names are case senstive). Library was required but suitable match not found`
verify-token-polygon:
	forge verify-contract \
	--rpc-url $(RPC_POLYGON) \
	--verifier-url 'https://api-amoy.polygonscan.com/api' \
	-e $(POLYGON_API_KEY) \
	0x753da027758f33f9dF35b8529Fa9b2e78664DfE5 \
	contracts/ChainlessUSD.sol:ChainlessUSD \
	--constructor-args 0x000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000006edce65403992e310a62460808c4b910d972f10f00000000000000000000000077774a499f484378e71e6692832b6abf0b2350d4000000000000000000000000000000000000000000000000000000000000000d556e636861696e6564205553440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000045555534400000000000000000000000000000000000000000000000000000000 \
	--watch







# doesnt work because some weird library stuff

# verify-token-unichain:
# 	forge verify-contract \
# 	--rpc-url $(RPC_UNICHAIN) \
# 	--verifier blockscout \
# 	--verifier-url 'https://unichain-sepolia.blockscout.com/api/' \
# 	0x9DdE77B61FC4F08177f14cb254148BF7cC85A8C5 \
# 	contracts/ChainlessUSD.sol:ChainlessUSD \
# 	--constructor-args  \
# 	--watch

# verify-token-scroll:
# 	forge verify-contract \
# 	--rpc-url $(RPC_SCROLL) \
# 	--verifier blockscout \
# 	--verifier-url 'https://scroll-sepolia.blockscout.com/api/' \
# 	0xA8FF03a3aF16A07e505Fa7b5c1e3E2726D9787A3 \
# 	contracts/ChainlessUSD.sol:ChainlessUSD \
# 	--constructor-args 0x000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000c0000000000000000000000000b8815f3f882614048cbe201a67ef9c6f10fe503500000000000000000000000012348e0f1d209896a76768a283b2b5dd42c9f460000000000000000000000000000000000000000000000000000000000000000d556e636861696e6564205553440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000045555534400000000000000000000000000000000000000000000000000000000 \
# 	--watch

# cast abi-encode 'constructor(string,string,address,address)' 'Unchained USD' 'UUSD' 0xb8815f3f882614048CbE201a67eF9c6F10fe5035 0x1001F662C0dE98e426870A9107f14A0c8C052Aa0
# verify-token-polygon:
# 	forge verify-contract \
# 	--rpc-url $(RPC_POLYGON) \
# 	--verifier-url 'https://api-amoy.polygonscan.com/api' \
# 	-e $(POLYGON_API_KEY) \
# 	0xe9839aECCCC989C7F736E8C5a787591b1894f65C \
# 	contracts/ChainlessUSD.sol:ChainlessUSD \
# 	--constructor-args 0x000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000c0000000000000000000000000b8815f3f882614048cbe201a67ef9c6f10fe50350000000000000000000000001001f662c0de98e426870a9107f14a0c8c052aa0000000000000000000000000000000000000000000000000000000000000000d556e636861696e6564205553440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000045555534400000000000000000000000000000000000000000000000000000000 \
# 	--watch

# verify-balance-zircuit:
# 	forge verify-contract \
# 	--rpc-url $(RPC_ZIRCUIT) \
# 	--verifier-url https://explorer.zircuit.com/api/contractVerifyHardhat \
# 	-e $(ZIRCUIT_API_KEY) \
# 	0x1d9F50D64511770695284D98E882Fb4B436191ad \
# 	contracts/ChainlessBalance.sol:ChainlessBalance
# 	# --guess-constructor-args \
# 	# --watch

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

