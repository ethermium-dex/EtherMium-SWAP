var dmexContract = '0x1677F52cfD5D40e3e32803884031435a78370aA4';
var tokenAddress = '0xC93dCe4D4985Bf5dfa7a85498f56AeC33A6e0Ef2';
var owner = '0x95445852148540acB6FcB9e39856D15F1C416381';
var factoryAddress = '0x408AD646a3a3eBebCf8eaefFBBDb35A4D05EFd77';
let Web3 = require('web3');
const solc = require('solc');
const path = require('path');
const fs = require('fs');
const _ = require('lodash');
const web3 = new Web3();
web3.setProvider(new web3.providers.HttpProvider('https://ropsten.infura.io/v3/8ee40c0abae6485086cdedd1faf22e7e'));


const pTokens = require('ptokens');
const ptokens = new pTokens({
    pbtc: {
      ethProvider: web3.currentProvider,
      btcNetwork: 'testnet'
    }
});

class Tester {

    constructor()
    {
        this.init();        
    }

    async init(contractCode)
    {
    	console.log(await this.computeBtcDepositAddress(owner, tokenAddress, dmexContract, factoryAddress));
    }

    generateContractCode(owner, token, dmexContract)
    {
    	const myContractPath = path.resolve('./contract/deposit-contract.sol');
    	const sourceCode = fs.readFileSync(myContractPath,'utf8');
    	
    	var compiled = _.template(sourceCode);
    	var output = compiled({
    		token: token,
    		owner: owner,
    		dmexContract: dmexContract
    	});

    	return output;
    }

    async compileContract(code)
    {
    	var input = {
		    language: 'Solidity',
		    sources: {
		        'deposit-contract.sol' : {
		            content: code
		        }
		    },
		    settings: {
		        outputSelection: {
		            '*': {
		                '*': [ '*' ]
		            }
		        }
		    }
		}; 

		const output = JSON.parse(solc.compile(JSON.stringify(input)));

		return '0x'+output.contracts['deposit-contract.sol']['DepositToDMEX'].evm.bytecode.object;
		
    }

	// deterministically computes the smart contract address given
	// the account the will deploy the contract (factory contract)
	// the salt as uint256 and the contract bytecode
	buildCreate2Address(creatorAddress, saltHex, byteCode) {
		return `0x${web3.utils.sha3(`0x${[
		'ff',
		creatorAddress,
		saltHex,
		web3.utils.sha3(byteCode)
		].map(x => x.replace(/0x/, ''))
		.join('')}`).slice(-40)}`.toLowerCase();
	}

	// converts an int to uint256
	numberToUint256(value) {
	  	const hex = value.toString(16);
	  	return `0x${'0'.repeat(64-hex.length)}${hex}`;
	}

	// encodes parameter to pass as contract argument
	encodeParam(dataType, data) {
	  	return web3.eth.abi.encodeParameter(dataType, data);
	}

	// returns true if contract is deployed on-chain
	async isContract(address) {
	  	const code = await web3.eth.getCode(address);
	  	return code.slice(2).length > 0
	}

	async computeBtcDepositAddress(owner, tokenAddress, dmexContract, factoryAddress)
	{
		var contractCode = this.generateContractCode(owner, tokenAddress, dmexContract);

		var depositContractBytecode = await this.compileContract(contractCode);


		// constructor arguments are appended to contract bytecode
		const bytecode = `${depositContractBytecode}${this.encodeParam('address', tokenAddress).slice(2)}`
		const salt = 1

		const computedAddr = this.buildCreate2Address(
		  factoryAddress,
		  this.numberToUint256(salt),
		  bytecode
		);

		var btcDepositAddress = await ptokens.pbtc.getDepositAddress(computedAddr);	
		
		var isCont = await this.isContract(computedAddr);

		var result = {
			depositContract: computedAddr,
			btcDepositAddress: btcDepositAddress.toString(),
			bytecode: bytecode,
			owner: owner
		};

		return result;
	}
}

module.export = new Tester();

