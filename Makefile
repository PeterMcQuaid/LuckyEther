-include .env

NETWORK=$(ANVIL)
FUND_AMOUNT=10ether
PAUSER_CONTRACT=
NEW_OWNER=
EMPTY_CONTRACT=
IMPLEMENTATION=
PROXY_ADMIN=
PROXY=

# Fund the deployer account on local fork
fund-deployer:
	@echo "Funding $(DEPLOYER_ADDRESS) with $(FUND_AMOUNT) on local $(NETWORK) fork"
	@cast send --value $(FUND_AMOUNT) --private-key $(ANVIL_ACCOUNT_0_PRIV_KEY) $(DEPLOYER_ADDRESS) 

# Tests

test-anvil:
	@echo "Running all tests on Anvil"
	@forge test --sender $(DEPLOYER_ADDRESS) -v

test-sepolia:
	@echo "Running all tests on Sepolia"
	@forge test --fork-url $(RPC_SEPOLIA) --sender $(DEPLOYER_ADDRESS) -v

test-goerli-arbitrum:
	@echo "Running all tests on Goerli-Arbitrum"
	@forge test --fork-url $(RPC_ARBITRUM_GOERLI) --sender $(DEPLOYER_ADDRESS) -v

# Deploy

deploy-pauser:
	@echo "Deploying PauserRegistry on $(NETWORK)"
	@forge script script/DeployPauserRegistry.s.sol:DeployPauserRegistry --sig "run(address[],address[])" \
	$(PAUSERS) $(UNPAUSERS) --fork-url $(NETWORK) --verify -vvv \
	--keystores ~/.foundry/keystores/LuckyEtherDeployer --password $(DEPLOYER_KEYSTORE_PASSWORD) --broadcast

update-pauser-owner:	
	@echo "Updating PauserRegistry Registry owner on $(NETWORK) to $(NEW_OWNER)"
	@forge script script/DeployPauserRegistry.s.sol:UpdatePauserRegistryOwnerScript --sig "run(address,address)" \
	$(PAUSER_CONTRACT) $(NEW_OWNER) --fork-url $(NETWORK) -vvv --keystores ~/.foundry/keystores/LuckyEtherDeployer \
	--password $(DEPLOYER_KEYSTORE_PASSWORD) --broadcast

deploy-emptyContract:
	@echo "Deploying EmptyContract on $(NETWORK)"
	@forge script script/DeployLotteryContract.s.sol:EmptyContractDeployScript --fork-url $(NETWORK) --verify -vvv \
	--keystores ~/.foundry/keystores/LuckyEtherDeployer --password $(DEPLOYER_KEYSTORE_PASSWORD) --broadcast

deploy-proxy:
	@echo "Deploying TransparentUpgradeableProxy on $(NETWORK)"
	@forge script script/DeployLotteryContract.s.sol:TransparentUpgradeableProxyDeployScript --sig "run(address)" \
	$(EMPTY_CONTRACT) --fork-url $(NETWORK) --verify -vvv --keystores ~/.foundry/keystores/LuckyEtherDeployer \
	--password $(DEPLOYER_KEYSTORE_PASSWORD) --broadcast

deploy-implementation:
	@echo "Deploying Implementation Lottery Contract on $(NETWORK)"
	@forge script script/DeployLotteryContract.s.sol:LotteryDeployScript --fork-url $(NETWORK) --verify -vvv \
	--keystores ~/.foundry/keystores/LuckyEtherDeployer --password $(DEPLOYER_KEYSTORE_PASSWORD) --broadcast

upgrade-implementation:
	@echo "Updating Implementation contract to $(IMPLEMENTATION)"
	@forge script script/DeployLotteryContract.s.sol:InitializeImplementationScript --sig "run(address,address,address,address)" \
	$(PROXY_ADMIN) $(PROXY) $(IMPLEMENTATION) $(PAUSER_CONTRACT) --fork-url $(NETWORK) -vvv \
	--keystores ~/.foundry/keystores/LuckyEtherDeployer --password $(DEPLOYER_KEYSTORE_PASSWORD) --broadcast

update-proxy-admin-owner:
	@echo "Updating ProxyAdmin owner on $(NETWORK) to $(NEW_OWNER)"
	@forge script script/DeployLotteryContract.s.sol:UpdateProxyAdminOwnerScript --sig "run(address,address)" \
	$(PROXY_ADMIN) $(NEW_OWNER) --fork-url $(NETWORK) -vvv --keystores ~/.foundry/keystores/LuckyEtherDeployer \
	--password $(DEPLOYER_KEYSTORE_PASSWORD) --broadcast