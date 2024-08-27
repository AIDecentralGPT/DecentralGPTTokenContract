compile:
	npx hardhat compile

deploy:
	npx hardhat run script/deploy_upgradable.ts --network dbcTestnet

verify:
	npx hardhat verify --network dbcTestnet 0x82b1a3d719dDbFDa07AD1312c3063a829e1e66F1

upgrade:
	npx hardhat run script/upgrade.ts --network dbcTestnet
