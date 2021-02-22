const fixedMinePool = artifacts.require("fixedMinePool_Timed");
const CFNX = artifacts.require("CFNX");
const BN = require("bn.js");
let PeriodTime = 90*86400;
const {migrateTimedMinePool,migrateTestMinePool} = require("./testFunctions.js")
contract('fixedMinePool_Timed', function (accounts){
    it('fixedMinePool_Timed big period begin', async function (){
        let contracts = await migrateTimedMinePool(accounts);
        let nowId = await contracts.minePool.getCurrentPeriodID();
        assert.equal(nowId.toNumber(),1,"getCurrentPeriodID Error");
        await contracts.minePool.setTime(1500);
        await contracts.minePool.stakeFPTA(100000);
        await contracts.minePool.stakeFPTB(100000,2);
        await contracts.minePool.setMineCoinInfo(contracts.MINE.address,2000000,1);
        let mineBalance = await contracts.minePool.getMinerBalance(accounts[0],contracts.MINE.address);
        assert.equal(mineBalance.toNumber(),0,"getMinerBalance error");
        await contracts.minePool.setTime(1600);
        mineBalance = await contracts.minePool.getMinerBalance(accounts[0],contracts.MINE.address);
        let realMine = 2000000*190;
        console.log(mineBalance.toNumber(),realMine);
        assert(Math.abs(mineBalance.toNumber()-realMine)<20,"getMinerBalance error");
        await contracts.minePool.redeemMinerCoin(contracts.MINE.address,mineBalance);
        mineBalance = await contracts.minePool.getMinerBalance(accounts[0],contracts.MINE.address);
        assert.equal(mineBalance.toNumber(),0,"getMinerBalance error");
        await contracts.minePool.stakeFPTA(100000,{from:accounts[1]});
        await contracts.minePool.stakeFPTB(100000,4,{from:accounts[1]});
        mineBalance = await contracts.minePool.getMinerBalance(accounts[1],contracts.MINE.address);
        assert.equal(mineBalance.toNumber(),0,"getMinerBalance error");
        await contracts.minePool.setTime(1700);
        mineBalance = await contracts.minePool.getMinerBalance(accounts[0],contracts.MINE.address);
        realMine = 1000000*100;
        assert(Math.abs(mineBalance.toNumber()-realMine)<20,"getMinerBalance error");
        mineBalance = await contracts.minePool.getMinerBalance(accounts[1],contracts.MINE.address);
        realMine = 1000000*320;
        assert(Math.abs(mineBalance.toNumber()-realMine)<20,"getMinerBalance error");

        await contracts.minePool.redeemMinerCoin(contracts.MINE.address,mineBalance,{from:accounts[1]});
        mineBalance = await contracts.minePool.getMinerBalance(accounts[1],contracts.MINE.address);
        assert.equal(mineBalance.toNumber(),0,"getMinerBalance error");
    });
    it('fixedMinePool_Timed premium distributing big period begin', async function (){
        let contracts = await migrateTimedMinePool(accounts);
        let nowId = await contracts.minePool.getCurrentPeriodID();
        assert.equal(nowId.toNumber(),1,"getCurrentPeriodID Error");
        await contracts.minePool.stakeFPTA(100000);
        await contracts.minePool.stakeFPTB(100000,2);
        await contracts.minePool.setMineCoinInfo(contracts.MINE.address,2000000,1);
        await contracts.minePool.setTime(1500);
        await contracts.minePool.setOperator(0,accounts[0]);
        for (var i=1;i<150;i++){
            await contracts.minePool.distributePremium(contracts.USDC.address,i,10000);
        }
        realMine = 10000;
        let mineBalance = await contracts.minePool.getUserLatestPremium(accounts[0],contracts.USDC.address);
        assert.equal(mineBalance.toNumber(),realMine,"getMinerBalance error");
        let Balance0 = await contracts.USDC.balanceOf(contracts.minePool.address); 
        await contracts.minePool.redeemPremium();
        let Balance1 = await contracts.USDC.balanceOf(contracts.minePool.address); 
        assert.equal(mineBalance.toNumber(),Balance0.toNumber()-Balance1.toNumber(),"redeemPremium error");

        mineBalance = await contracts.minePool.getUserLatestPremium(accounts[0],contracts.USDC.address);
        assert.equal(mineBalance.toNumber(),0,"getMinerBalance error");
        await contracts.minePool.stakeFPTA(100000,{from:accounts[1]});
        await contracts.minePool.stakeFPTB(100000,12,{from:accounts[1]});
        await contracts.minePool.setTime(3000);
        for (var i=150;i<300;i++){
            await contracts.minePool.distributePremium(contracts.USDC.address,i,10000);
        }
        mineBalance = await contracts.minePool.getUserLatestPremium(accounts[0],contracts.USDC.address);
        assert.equal(mineBalance.toNumber(),0,"getMinerBalance error");
        mineBalance = await contracts.minePool.getUserLatestPremium(accounts[1],contracts.USDC.address);
        assert.equal(mineBalance.toNumber(),110000,"getMinerBalance error");
        await contracts.minePool.stakeFPTB(100000,12);
        await contracts.minePool.setTime(4500);
        for (var i=300;i<450;i++){
            await contracts.minePool.distributePremium(contracts.USDC.address,i,10000);
        }
        mineBalance = await contracts.minePool.getUserLatestPremium(accounts[0],contracts.USDC.address);
        assert.equal(mineBalance.toNumber(),110000,"getMinerBalance error");
        mineBalance = await contracts.minePool.getUserLatestPremium(accounts[1],contracts.USDC.address);
        assert.equal(mineBalance.toNumber(),110000,"getMinerBalance error");
    });
});