const {expectRevert, time} = require('@openzeppelin/test-helpers');
const basketMgr = artifacts.require('BasketManager.sol');
const forgeValidator = artifacts.require('ForgeValidator.sol');
const tokenManager = artifacts.require('TokenManager.sol');
const erc20 = artifacts.require('Token');
const mock_aave = artifacts.require('MockAAVE');

contract('Masset - Mint', ([alice, bob, carol, dev, minter]) => {

    beforeEach(async () => {

      this.tokenMgr = await tokenManager.new("XSDT", "XSDT", { from: alice });

        // mock erc20
        this.erc20 = await erc20.new('DAI', 'DAI', { from: alice });
        this.erc20_1 = await erc20.new('DAI2', 'DAI2', { from: alice });
        // deploy ccontracts
        // this.basketMgr = await basketMgr.new();
        // this.forgeValidator = await forgeValidator.new();
        // this.xsdt = await mAsset.new("XSDT", "XSDT", { from: alice });

        // deploy mock platform
        // this.aave = await mock_aave.new();

        // console.log("before init", await this.xsdt.forgeValidator())
        // initialize mAsset
        // await this.xsdt.initialize(this.basketMgr.address, this.xsdt.address);
        // console.log("after init", await this.xsdt.forgeValidator())
    });

    it('Mint', async () => {
        await this.tokenMgr.create("DAI", "DAI");
        // console.log("a is", a)
        let totalAsstes = (await this.tokenMgr.totalAssets()).toString()
        console.log('totalAsstes', totalAsstes);
        let newContract = await this.tokenMgr.customAssets(totalAsstes-1)
        console.log(newContract)

        console.log("before balance", (await this.erc20.balanceOf(alice)).toString())
        // mint token to user.
        await this.erc20.mint(alice, 100000);
        console.log("after balance", (await this.erc20.balanceOf(alice)).toString())

        console.log("before balance1", (await this.erc20_1.balanceOf(alice)).toString())
        // mint token to user.
        await this.erc20_1.mint(alice, 50000);
        console.log("after balance1", (await this.erc20_1.balanceOf(alice)).toString())

        // approve to mAsset contract
        await this.erc20.approve(this.tokenMgr.address, 100000);
        await this.erc20_1.approve(this.tokenMgr.address, 50000);

        this.newCtr = await erc20.at(newContract)
        console.log('before new', (await this.newCtr.balanceOf(alice)).toString())
        await this.tokenMgr.mintMulti(
            newContract,
            [this.erc20.address, this.erc20_1.address],
            [10, 20],
            [false, false],
            alice
        )
        console.log('after new', (await this.newCtr.balanceOf(alice)).toString())
        
        console.log('before new', (await this.newCtr.balanceOf(alice)).toString())
        await this.tokenMgr.redeem(newContract, 1)
        console.log('after new', (await this.newCtr.balanceOf(alice)).toString())
        // // set platform config of `basketMgr`
        // console.log('before set', await this.basketMgr.mAsset())
        // await this.basketMgr.initialize(this.xsdt.address, [this.erc20.address], [this.aave.address], [10**8], [false]);
        // console.log('after set', await this.basketMgr.mAsset())

        // xsdt contract approve platform: aavev
        // this.xsdt.approve(this.aave.address, 10000000)
        // BUG!!!
        // this.xsdt.approve(bob, 10000000, { from: bob })

        // console.log('before mint', (await this.xsdt.balanceOf(alice)).toString())
        // await this.xsdt.mint(this.erc20.address, 100)
        // console.log('after mint', (await this.xsdt.balanceOf(alice)).toString())

        // console.log("before redeem, underlying balance:", (await this.erc20.balanceOf(alice)).toString())
        // // await debug(this.xsdt.redeem(this.erc20.address, 6))
        // await this.xsdt.redeem(this.erc20.address, 6)
        // console.log("after redeem, underlying balance:", (await this.erc20.balanceOf(alice)).toString())
        // console.log('after redeem', (await this.xsdt.balanceOf(alice)).toString())

    });

});