-include .env

test-anvil:
	forge test --sender $(DEPLOYER_ADDRESS) -v

test-sepolia:
	forge test --fork-url $(RPC_SEPOLIA) --sender $(DEPLOYER_ADDRESS) -v

test-goerli-arbitrum:
	forge test --fork-url $(RPC_ARBITRUM_GOERLI) --sender $(DEPLOYER_ADDRESS) -v
