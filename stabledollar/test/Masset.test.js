const {expectRevert, time} = require('@openzeppelin/test-helpers');
const basketMgr = artifacts.require('BasketManager.sol');
const forgeValidator = artifacts.require('ForgeValidator.sol');
const mAsset = artifacts.require('Masset.sol');
const erc20 = artifacts.require('Token');
const mock_aave = artifacts.require('MockAAVE');

contract('Masset - Mint', ([alice, bob, carol, dev, minter]) => {

    beforeEach(async () => {
        // mock erc20
        this.erc20 = await erc20.new('DAI', 'DAI', { from: alice });
        // deploy ccontracts
        this.basketMgr = await basketMgr.new();
        this.forgeValidator = await forgeValidator.new();
        this.xsdt = await mAsset.new("XSDT", "XSDT", { from: alice });

        // deploy mock platform
        this.aave = await mock_aave.new();

        // console.log("before init", await this.xsdt.forgeValidator())
        // initialize mAsset
        await this.xsdt.initialize(this.basketMgr.address, this.xsdt.address);
        // console.log("after init", await this.xsdt.forgeValidator())
    });

    it('Mint', async () => {

        console.log("before balance", (await this.erc20.balanceOf(alice)).toString())
        // mint token to user.
        await this.erc20.mint(alice, 100000);
        console.log("after balance", (await this.erc20.balanceOf(alice)).toString())

        // approve to mAsset contract
        await this.erc20.approve(this.xsdt.address, 100000);

        // set platform config of `basketMgr`
        console.log('before set', await this.basketMgr.mAsset())
        await this.basketMgr.initialize(this.xsdt.address, [this.erc20.address], [this.aave.address], [10**8], [false]);
        console.log('after set', await this.basketMgr.mAsset())

        // xsdt contract approve platform: aavev
        this.xsdt.approve(this.aave.address, 10000000)
        // BUG!!!
        this.xsdt.approve(bob, 10000000, { from: bob })

        console.log('before mint', (await this.xsdt.balanceOf(alice)).toString())
        await this.xsdt.mint(this.erc20.address, 100)
        console.log('after mint', (await this.xsdt.balanceOf(alice)).toString())

        console.log("before redeem, underlying balance:", (await this.erc20.balanceOf(alice)).toString())
        // await debug(this.xsdt.redeem(this.erc20.address, 6))
        await this.xsdt.redeem(this.erc20.address, 6)
        console.log("after redeem, underlying balance:", (await this.erc20.balanceOf(alice)).toString())
        console.log('after redeem', (await this.xsdt.balanceOf(alice)).toString())

    });

});
