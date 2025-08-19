compile:
	npx hardhat compile

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

deploy_multi_sig-bsc-mainnet:
	source .env && npx hardhat run script/deploy_multi_sig.ts --network bsc

verify_multi_sig-bsc-mainnet:
	source .env && npx hardhat verify --network bsc $MULTI_SIG_CONTRACT

upgrade_multi_sig-bsc-mainnet:
	npx hardhat run script/upgrade_multi_sig.ts --network bsc
