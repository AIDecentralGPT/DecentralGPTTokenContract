compile:
	npx hardhat compile

deploy:
	npx hardhat run script/deploy_upgradable.ts --network dbcTestnet

verify:
	npx hardhat verify --network dbcTestnet 0xC260ed583545d036ed99AA5C76583a99B7E85D26

upgrade:
	npx hardhat run script/upgrade.ts --network dbcTestnet
