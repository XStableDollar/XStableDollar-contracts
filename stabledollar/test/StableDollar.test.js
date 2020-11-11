const {expectRevert, time} = require('@openzeppelin/test-helpers');
const XStableDollar = artifacts.require('XStableDollar');

contract('XStableDollar', ([alice, bob, carol, dev, minter]) => {

    beforeEach(async () => {
        this.ctl = await XStableDollar.new(alice, {from: alice});
    });

    it('TestCase_1', async () => {
        const devAddress = await this.ctl.devAddress();
        console.log('devAddress:', devAddress.valueOf())

        const random1 = await this.ctl.genRandNumber();

        console.log(random1);

        // console.log('currentVersion:', currentVersion.toString())

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

    xit('TestCase_2', async () => {

    });

});
