const { time, expectEvent} = require("@openzeppelin/test-helpers")
let utils = require('./utils.js');

let CFNC = artifacts.require("CFNX");
let TokenConverter = artifacts.require("TokenConverter");
let TokenConverterProxy = artifacts.require("TokenConverterProxy");

const BN = require("bn.js");
const assert = require('assert');

const ONE_HOUR = 60*60;
const ONE_DAY = ONE_HOUR * 24;
const ONE_MONTH = 30 * ONE_DAY;

contract('TokenConverter', function (accounts) {
    let cfnxAmount1 = new BN("60000000000000000000");
    let cfnxAmount2 = new BN("120000000000000000000");
    let cfnxAmount3 = new BN("125000000000000000000");
    let fnxAmount = new BN("90000000000000000000000");

    let CFNXInst;
    let FNXInst;
    let CvntInst;
    let CvntProxyInst;

    before(async () => {
        CFNXInst = await CFNC.new();
        console.log("cfnx address:" + CFNXInst.address);

        FNXInst = await CFNC.new();
        console.log("fnx address:" + CFNXInst.address);

        CvntInst = await TokenConverter.new();
        console.log("converter address:" + CvntInst.address);

        CvntProxyInst = await TokenConverterProxy.new(CvntInst.address);
        console.log("proxy address:" + CvntProxyInst.address);

        let tx = await CvntProxyInst.setParameter(CFNXInst.address,FNXInst.address,0,0,0);
        assert.equal(tx.receipt.status,true);
        ////init process
        tx = await CFNXInst.mint(accounts[1],cfnxAmount1);
        assert.equal(tx.receipt.status,true);

        tx = await CFNXInst.mint(accounts[2],cfnxAmount2);
        assert.equal(tx.receipt.status,true);

        tx = await CFNXInst.mint(accounts[3],cfnxAmount3);
        assert.equal(tx.receipt.status,true);

        tx = await FNXInst.mint(CvntProxyInst.address,fnxAmount);
        assert.equal(tx.receipt.status,true);

        tx = await CFNXInst.approve(CvntProxyInst.address,cfnxAmount1,{from:accounts[1]});
        assert.equal(tx.receipt.status,true);

        tx = await CFNXInst.approve(CvntProxyInst.address,cfnxAmount2,{from:accounts[2]});
        assert.equal(tx.receipt.status,true);

        tx = await CFNXInst.approve(CvntProxyInst.address,cfnxAmount3,{from:accounts[3]});
        assert.equal(tx.receipt.status,true);
    });

    it('User1 input CFNX and get 1/6 FNX', async function () {
        let beforeFnxUser =  await FNXInst.balanceOf(accounts[1]);
        let beforeCFnxBalanceUser = await CFNXInst.balanceOf(accounts[1]);
        console.log(beforeCFnxBalanceUser);
        console.log(await CFNXInst.allowance(accounts[1],CvntProxyInst.address));

        let beforeFnxBalanceProxy = await CFNXInst.balanceOf(CvntProxyInst.address);
        let tx = await CvntProxyInst.inputCfnxForInstallmentPay(cfnxAmount1,{from:accounts[1]});
        assert.equal(tx.receipt.status,true);

        let afterFnxUser =  await FNXInst.balanceOf(accounts[1]);
        let afterCFnxBalanceUser = await CFNXInst.balanceOf(accounts[1]);
        let afterFnxBalanceProxy = await CFNXInst.balanceOf(CvntProxyInst.address);

        let diffCFNXUser = web3.utils.fromWei(new BN(beforeCFnxBalanceUser)) - web3.utils.fromWei(new BN(afterCFnxBalanceUser));
        console.log("CFNX diff User:" + diffCFNXUser);
        let diffContract = web3.utils.fromWei(new BN(afterFnxBalanceProxy)) - web3.utils.fromWei(new BN(beforeFnxBalanceProxy));
        console.log("CFNX diff contract:" + diffContract);
        assert.equal(diffCFNXUser,diffContract);

        let diffFNXUser = web3.utils.fromWei(new BN(afterFnxUser)) - web3.utils.fromWei(new BN(beforeFnxUser));
        console.log("FNX diff user:" + diffFNXUser);
        assert.equal(diffFNXUser,diffContract/6);

        let lockedBalance = await CvntProxyInst.lockedBalanceOf(accounts[1]);
        console.log(lockedBalance);
        assert.equal(web3.utils.fromWei(lockedBalance),web3.utils.fromWei(cfnxAmount1)*5/6);
    })


    it('Get FNX 2/6,3/6 part', async function () {
        await time.increase(2*ONE_MONTH + 1);
        let beforeFnxUser =  await FNXInst.balanceOf(accounts[1]);
        let tx = await CvntProxyInst.claimFnxExpiredReward({from:accounts[1]});
        assert.equal(tx.receipt.status,true);
        await utils.sleep(1000);
        let afterFnxUser =  await FNXInst.balanceOf(accounts[1]);
        let diffFNXUser = web3.utils.fromWei(new BN(afterFnxUser)) - web3.utils.fromWei(new BN(beforeFnxUser));
        console.log("2/6,3/6 FNX diff user:" + diffFNXUser);
        assert.equal(diffFNXUser,web3.utils.fromWei(cfnxAmount1)*2/6);

        let lockedBalance = await CvntProxyInst.lockedBalanceOf(accounts[1]);
        assert.equal(web3.utils.fromWei(lockedBalance),web3.utils.fromWei(cfnxAmount1)*3/6);
    })

    it('Get FNX 4/6,5/6,6/6 part', async function () {
        await time.increase(4*ONE_MONTH + 1);
        let beforeFnxUser =  await FNXInst.balanceOf(accounts[1]);
        let tx = await CvntProxyInst.claimFnxExpiredReward({from:accounts[1]});
        assert.equal(tx.receipt.status,true);
        await utils.sleep(1000);
        let afterFnxUser =  await FNXInst.balanceOf(accounts[1]);
        let diffFNXUser = web3.utils.fromWei(new BN(afterFnxUser)) - web3.utils.fromWei(new BN(beforeFnxUser));
        console.log("4,5,6/6 FNX diff user:" + diffFNXUser);
        assert.equal(diffFNXUser,web3.utils.fromWei(cfnxAmount1)*3/6);

        let lockedBalance = await CvntProxyInst.lockedBalanceOf(accounts[1]);
        assert.equal(web3.utils.fromWei(lockedBalance),0);
    })

})