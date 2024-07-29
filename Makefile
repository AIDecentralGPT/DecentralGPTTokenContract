compile:
	npx hardhat compile

deploy:
	npx hardhat run script/deploy_upgradable.ts --network dbcTestnet

verify:
    npx hardhat  verify  --network dbcTestnet  0x31c494542F3eA6E25f707EC41c88344aA92Fa668

upgrade:
	npx hardhat run script/upgrade.ts --network dbcTestnet
