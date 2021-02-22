const fixedMinePool = artifacts.require("fixedMinePool_test");
const CFNX = artifacts.require("CFNX");
const BN = require("bn.js");
let PeriodTime = 90*86400;
const {migrateNormalMinePool} = require("./testFunctions.js")
contract('fixedMinePool', function (accounts){
    it('fixedMinePool Locked stake FPTB function', async function (){
        let contracts = await migrateNormalMinePool(accounts);
        await testViolation("msg.sender is not Owner",async function(){
            await contracts.minePool.redeemOut(contracts.CFNXA.adddress,10000000,{from:accounts[1]});
        });
        await testViolation("stake FPTB imput error period",async function(){
            await contracts.minePool.stakeFPTB(1000000,13);
        });
        await testViolation("haven't stake FPTB want changeFPTBLockedPeriod",async function(){
            await contracts.minePool.changeFPTBLockedPeriod(5);
        });
        await testViolation("unstake FPTA balance is insufficient",async function(){
            await contracts.minePool.unstakeFPTA(1000000);
        });
        await testViolation("unstake FPTB balance is insufficient",async function(){
            await contracts.minePool.unstakeFPTB(1000000);
        });
        await testViolation("lockAirDrop FPTB is not operator",async function(){
            await contracts.minePool.lockAirDrop(accounts[1],1000000);
        });
        await contracts.minePool.stakeFPTB(1000000,0);
        await testViolation("unstake FPTB before expired time",async function(){
            await contracts.minePool.unstakeFPTB(1000000);
        });
        await contracts.minePool.stakeFPTB(1000000,5);
        await testViolation("stake FPTB imput less period",async function(){
            await contracts.minePool.stakeFPTB(1000000,3);
        });
        await testViolation("changing FPTB locked period input less period",async function(){
            await contracts.minePool.changeFPTBLockedPeriod(3);
        });
        await testViolation("stake FPTB imput larger period",async function(){
            await contracts.minePool.stakeFPTB(1000000,13);
        });
        await testViolation("changing FPTB locked period input larger period",async function(){
            await contracts.minePool.changeFPTBLockedPeriod(13);
        });
        await testViolation("unstake FPTB before expired time",async function(){
            await contracts.minePool.unstakeFPTB(1000000);
        });
    });
});
async function testViolation(message,testFunc){
    bErr = false;
    try {
        await testFunc();        
    } catch (error) {
        console.log(error);
        bErr = true;
    }
    assert(bErr,message);
}