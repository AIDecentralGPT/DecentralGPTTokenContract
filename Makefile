compile:
	npx hardhat compile

deploy-bsc-testnet:
	npx hardhat run script/deploy_upgradable.ts --network bscTestnet

verify-bsc-testnet:
	source .env && npx hardhat verify --network bscTestnet $PROXY_CONTRACT

upgrade-bsc-testnet:
	npx hardhat run script/upgrade.ts --network bscTestnet

deploy-bsc:
	npx hardhat run script/deploy_upgradable.ts --network bsc

verify-bsc:
	source .env && npx hardhat verify --network bsc $PROXY_CONTRACT

upgrade-bsc:
	npx hardhat run script/upgrade.ts --network bsc




deploy-dbc-mainnet:
	npx hardhat run script/deploy_upgradable.ts --network dbcMainnet

verify-dbc-mainnet:
	source .env && npx hardhat verify --network dbcMainnet $PROXY_CONTRACT

upgrade-dbc-mainnet:
	npx hardhat run script/upgrade.ts --network dbcMainnet

deploy_multi_sig-dbc-mainnet:
	source .env && npx hardhat run script/deploy_multi_sig.ts --network dbcMainnet

verify_multi_sig-dbc-mainnet:
	source .env && npx hardhat verify --network dbcMainnet $MULTI_SIG_CONTRACT

upgrade_multi_sig-dbc-mainnet:
	npx hardhat run script/upgrade_multi_sig.ts --network dbcMainnet
