const fMinePool = artifacts.require("fixedMinePool");
const fixedMinePool = artifacts.require("fixedMinePool_test");
const fixedMinePool_Timed = artifacts.require("fixedMinePool_Timed");
const minePoolProxy = artifacts.require("testMinePoolProxy");
const CFNX = artifacts.require("CFNX");
exports.migrateNormalMinePool =  async function (accounts){
    let CFNXA = await CFNX.new();
    let CFNXB = await CFNX.new();
    let USDC = await CFNX.new();
    let Mine = await CFNX.new();
    let startTime = 10000000;
    let minePoolImpl = await fMinePool.new(CFNXA.address,CFNXB.address,startTime);
    let minePool = await minePoolProxy.new(minePoolImpl.address,CFNXA.address,CFNXB.address,startTime);
    await CFNXA.mint(accounts[0],1000000000000000);
    await CFNXA.approve(minePool.address,1000000000000000);
    await CFNXB.mint(accounts[0],1000000000000000);
    await CFNXB.approve(minePool.address,1000000000000000);

    await CFNXA.mint(accounts[1],1000000000000000,);
    await CFNXA.approve(minePool.address,1000000000000000,{from:accounts[1]});
    await CFNXB.mint(accounts[1],1000000000000000);
    await CFNXB.approve(minePool.address,1000000000000000,{from:accounts[1]});
    await USDC.mint(accounts[0],1000000000000000);
    await USDC.approve(minePool.address,1000000000000000);
    await USDC.mint(accounts[1],1000000000000000);
    await USDC.approve(minePool.address,1000000000000000,{from:accounts[1]});
    await Mine.mint(minePool.address,1000000000000000);
    return {
        minePool : minePool,
        CFNXA : CFNXA,
        CFNXB : CFNXB,
        USDC : USDC,
        MINE : Mine
    }
}
exports.migrateTestMinePool =  async function (accounts){
    let CFNXA = await CFNX.new();
    let CFNXB = await CFNX.new();
    let USDC = await CFNX.new();
    let Mine = await CFNX.new();
    let startTime = 10000000;
    let minePoolImpl = await fixedMinePool.new(CFNXA.address,CFNXB.address,startTime);
    let minePool = await minePoolProxy.new(minePoolImpl.address,CFNXA.address,CFNXB.address,startTime);
    await CFNXA.mint(accounts[0],1000000000000000);
    await CFNXA.approve(minePool.address,1000000000000000);
    await CFNXB.mint(accounts[0],1000000000000000);
    await CFNXB.approve(minePool.address,1000000000000000);

    await CFNXA.mint(accounts[1],1000000000000000,);
    await CFNXA.approve(minePool.address,1000000000000000,{from:accounts[1]});
    await CFNXB.mint(accounts[1],1000000000000000);
    await CFNXB.approve(minePool.address,1000000000000000,{from:accounts[1]});
    await USDC.mint(accounts[0],1000000000000000);
    await USDC.approve(minePool.address,1000000000000000);
    await USDC.mint(accounts[1],1000000000000000);
    await USDC.approve(minePool.address,1000000000000000,{from:accounts[1]});
    await Mine.mint(minePool.address,1000000000000000);
    return {
        minePool : minePool,
        CFNXA : CFNXA,
        CFNXB : CFNXB,
        USDC : USDC,
        MINE : Mine
    }
}
exports.migrateTimedMinePool =  async function (accounts){
    let CFNXA = await CFNX.new();
    let CFNXB = await CFNX.new();
    let USDC = await CFNX.new();
    let Mine = await CFNX.new();
    let startTime = 0;
    let minePoolImpl = await fixedMinePool_Timed.new(CFNXA.address,CFNXB.address,startTime);
    let minePool = await minePoolProxy.new(minePoolImpl.address,CFNXA.address,CFNXB.address,startTime);
    await CFNXA.mint(accounts[0],1000000000000000);
    await CFNXA.approve(minePool.address,1000000000000000);
    
    await CFNXB.mint(accounts[0],1000000000000000);
    await CFNXB.approve(minePool.address,1000000000000000);

    await CFNXA.mint(accounts[1],1000000000000000,);
    await CFNXA.approve(minePool.address,1000000000000000,{from:accounts[1]});
    await CFNXB.mint(accounts[1],1000000000000000);
    await CFNXB.approve(minePool.address,1000000000000000,{from:accounts[1]});
    await USDC.mint(accounts[0],1000000000000000);
    await USDC.approve(minePool.address,1000000000000000);
    await USDC.mint(accounts[1],1000000000000000);
    await USDC.approve(minePool.address,1000000000000000,{from:accounts[1]});
    await Mine.mint(minePool.address,1000000000000000);
    return {
        minePool : minePool,
        CFNXA : CFNXA,
        CFNXB : CFNXB,
        USDC : USDC,
        MINE : Mine
    }
}
function calculateDistribution(fptA,fptB){
    return (fptA+fptB+Math.min(fptA,fptB*10)*20)*1000;
}
function calculateWeightDistribution(distribution,getId,maxId){
    if (getId > maxId){
        return 0;
    }
    return distribution *(maxId-getId+4);
}

exports.checkUserDistribution =  async function (contracts,account){
    let fptA = await contracts.minePool.getUserFPTABalance(account);
    let fptB = await contracts.minePool.getUserFPTBBalance(account);
    let result = await contracts.minePool.getDistributionCal(account);
    let distribution = calculateDistribution(fptA.toNumber(),fptB.toNumber());
    assert.equal(result.toNumber(),distribution,"getDistributionCal Error");
    result = await contracts.minePool.getUserDistribution(account);
    assert.equal(result.toNumber(),distribution,"getUserDistribution Error");
    let nowId = await contracts.minePool.getCurrentPeriodID();
    let maxId = await contracts.minePool.getUserMaxPeriodId(account);
    var i = nowId.toNumber();
    for (;i<=maxId.toNumber();i++){
        result = await contracts.minePool.getPeriodWeightDistribution(i);
        assert.equal(result.toNumber(),calculateWeightDistribution(distribution,i,maxId.toNumber()),"getPeriodWeightDistribution Error");
    }
    
    result = await contracts.minePool.getPeriodWeightDistribution(i);
    assert.equal(result.toNumber(),calculateWeightDistribution(distribution,i,maxId.toNumber()),"getPeriodWeightDistribution Error");
    assert.equal(result.toNumber(),0,"getPeriodWeightDistribution Error");
}