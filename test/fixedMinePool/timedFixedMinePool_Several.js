const fixedMinePool = artifacts.require("fixedMinePool_Timed");
const CFNX = artifacts.require("CFNX");
const BN = require("bn.js");
let PeriodTime = 90*86400;
const {migrateTimedMinePool,migrateTestMinePool} = require("./testFunctions.js")
contract('fixedMinePool_Timed', function (accounts){
    it('fixedMinePool_Timed several people mined', async function (){
        let contracts = await migrateTimedMinePool(accounts);
        await contracts.minePool.setMineCoinInfo(contracts.MINE.address,2000000,1);
        for(var i=2;i<10;i++){
            await contracts.CFNXA.mint(accounts[i],1000000000000000,);
            await contracts.CFNXA.approve(contracts.minePool.address,1000000000000000,{from:accounts[i]});
            await contracts.CFNXB.mint(accounts[i],1000000000000000);
            await contracts.CFNXB.approve(contracts.minePool.address,1000000000000000,{from:accounts[i]});
        }
        let nowId = await contracts.minePool.getCurrentPeriodID();
        assert.equal(nowId.toNumber(),1,"getCurrentPeriodID Error");
        await contracts.minePool.stakeFPTA(100000);
        await contracts.minePool.stakeFPTB(100000,0);
        for(var i=1;i<10;i++){
            await contracts.minePool.stakeFPTA(100000,{from:accounts[i]});
            await contracts.minePool.stakeFPTB(100000,i+1,{from:accounts[i]});
        }
        for (var i=0;i<150;i+=10){
            await contracts.minePool.setTime(i);
            let result = await contracts.minePool.getAverageLockedTime();
            console.log("average locked time",result.toString());
            result = await contracts.minePool.getUserCurrentAPY(accounts[9],contracts.MINE.address);
            console.log("getUserCurrentAPY",result.toString());
            result = await contracts.minePool.getCurrentTotalAPY(contracts.MINE.address);
            console.log("getCurrentAverageAPY",result.toString());
            
        }
    });
});