all    :
	dapp clean
	mkdir -p out
	/usr/local/bin/solc --overwrite ds-test/=lib/ds-test/src/ ds-test=lib/ds-test/src/index.sol --combined-json=abi,bin,bin-runtime,srcmap,srcmap-runtime,ast,metadata,storage-layout src/Encoder.sol src/Substitution.sol > out/dapp.sol.json
clean  :; dapp clean
test   :; dapp test
#deploy :; dapp create
