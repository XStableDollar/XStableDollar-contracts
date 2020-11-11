const {expectRevert, time} = require('@openzeppelin/test-helpers');
const mAsset = artifacts.require('Masset.sol');

contract('mAsset', ([alice, bob, carol, dev, minter]) => {

    beforeEach(async () => {
        this.ctl = await mAsset.new(alice, {from: alice});
    });

    it('Mint', async () => {
        // const version = await this.ctl.getVersion();
        // console.log('version:', version);

        const amount = await this.ctl.mint(bob, 2, {from: alice});
        console.log('amount: ', amount);
        // const random1 = await this.ctl.genRandNumber();
        // console.log(random1);

        // assert.equal(devAddress.valueOf(), alice);
        // assert.equal(currentVersion.valueOf(), '0');

        // 0.02, 0.05
        // await this.ctl.startVersion('20000000000000000', '50000000000000000', '20', '1024', {from: alice});
        // const currentVersion2 = await this.ctl.currentVersion();
        // console.log('currentVersion2:', currentVersion2.toString())

        // const allVersion = await this.ctl.allVersion('1')
        // console.log('allVersion.timeOutBlockSize:', allVersion.timeOutBlockSize.toString());
        // console.log('allVersion.basePrice:', allVersion.basePrice.toString());

        // const gridInfo = await this.ctl.getGridInfo('19')
        // console.log('gridInfo:', gridInfo[1].toString())

        // 1.4 1400000000000000000
        // const level = await this.ctl.getLevelByPrice('1400000000000000000');
        // // assert.equal(level.toString(), '0');
        // console.log('level:', level.toString())

        // const poolTotalFee = await this.ctl.poolTotalFee();
        // assert.equal(level.toString(), '0');
        // console.log('poolTotalFee:', poolTotalFee.toString())
    });

    // xit('TestCase_2', async () => {

    // });

});
