const fixedMinePool = artifacts.require("fixedMinePool_Timed");
const CFNX = artifacts.require("CFNX");
const BN = require("bn.js");
let PeriodTime = 90*86400;
const {migrateTimedMinePool,migrateTestMinePool} = require("./testFunctions.js")
contract('fixedMinePool_Timed', function (accounts){
    it('fixedMinePool_Timed one person mined max period', async function (){
        let contracts = await migrateTimedMinePool(accounts);
        let nowId = await contracts.minePool.getCurrentPeriodID();
        assert.equal(nowId.toNumber(),1,"getCurrentPeriodID Error");
        await contracts.minePool.stakeFPTA(100000);
        await contracts.minePool.stakeFPTB(100000,12);
        await contracts.minePool.setMineCoinInfo(contracts.MINE.address,1234567,1);
        let userPeriodId = await contracts.minePool.getUserMaxPeriodId(accounts[0]);
        assert.equal(userPeriodId.toNumber(),nowId.toNumber()+11,"getUserMaxPeriodId Error");
        await contracts.minePool.setTime(2100);
        mineBalance = await contracts.minePool.getMinerBalance(accounts[0],contracts.MINE.address);
        console.log("getMinerBalance : ",mineBalance.toNumber())
        let tx = await contracts.minePool.redeemMinerCoin(contracts.MINE.address,mineBalance);
        console.log(tx);
        mineBalance = await contracts.minePool.getMinerBalance(accounts[0],contracts.MINE.address);
        assert.equal(mineBalance.toNumber(),0,"getMinerBalance error");
    });
    it('fixedMinePool_Timed two persons mined', async function (){
        let contracts = await migrateTimedMinePool(accounts);
        let nowId = await contracts.minePool.getCurrentPeriodID();
        assert.equal(nowId.toNumber(),1,"getCurrentPeriodID Error");
        await contracts.minePool.stakeFPTA(100000);
        await contracts.minePool.stakeFPTB(100000,12);
        await contracts.minePool.setMineCoinInfo(contracts.MINE.address,1234567,1);
        await contracts.minePool.stakeFPTA(100000,{from:accounts[1]});
        await contracts.minePool.stakeFPTB(100000,12,{from:accounts[1]});
        let userPeriodId = await contracts.minePool.getUserMaxPeriodId(accounts[0]);
        assert.equal(userPeriodId.toNumber(),nowId.toNumber()+11,"getUserMaxPeriodId Error");
        await contracts.minePool.setTime(2100);
        mineBalance = await contracts.minePool.getMinerBalance(accounts[0],contracts.MINE.address);
        console.log("getMinerBalance : ",mineBalance.toNumber())
        let tx = await contracts.minePool.redeemMinerCoin(contracts.MINE.address,mineBalance);
        console.log(tx);
        mineBalance = await contracts.minePool.getMinerBalance(accounts[0],contracts.MINE.address);
        assert.equal(mineBalance.toNumber(),0,"getMinerBalance error");
        await contracts.minePool.setTime(4200);
        mineBalance = await contracts.minePool.getMinerBalance(accounts[0],contracts.MINE.address);
        console.log("getMinerBalance : ",mineBalance.toNumber())
        tx = await contracts.minePool.redeemMinerCoin(contracts.MINE.address,mineBalance);
        mineBalance = await contracts.minePool.getMinerBalance(accounts[0],contracts.MINE.address);
        assert.equal(mineBalance.toNumber(),0,"getMinerBalance error");
    });
    
});