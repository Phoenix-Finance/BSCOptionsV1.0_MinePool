/*
iv :  0x4Cc91a1D45C6a7b9db3c244417ceb6A43f1E7281
oracle :  0xEB91b81AaAbdc64B3EdfE0588AF851741EE46b42
price :  0xca5ad0C4967D81060d301Bf8AD24707fF2b099eA
optionsA :  0x303407EB8e55A69630506be7eEd73CB7541D3add
optionsB :  0xC8a698D33b09d1A95d9D6FAEc697EDA5BF5abdF5
minePoolA :  0xd6ed7EFB155Fb3803097400c0c994837822C84Ab
minePoolB :  0x1643D1e35Dfa6a344367bA93a599E866b55477BE
fptA :  0xB3d71938d085503E52d7eF837C2de8B63fE79203
fptB :  0xCB678aF010fbd70861b9D59fFec6870541B869b8
collateralPoolA :  0x166c5890a57aBA42cE1cA9eC135C387164545A48
collateralPoolB :  0xc99540E9f5f54c21089e63328f96e86cbFE711D7
managerA :  0x34F42C54B3b89Bf935FD28D0eE6E451AEA36390B
managerB :  0x3AC997b6588d22Bd354261389C5Cf88376fA6739
FNX :  0x2287Cd6E8da47CCBdc10B0b7C001e9CB66a436eb
USDC :  0xEc4a5858eF3c1E626c906b0DC3593c491646b651
USDT :  0x2F6902054B0ba3AC54611b3Daf7Ec500dEeEE9cf
*/
const IOptionMgrPoxy = artifacts.require("IOptionMgrPoxy");
const fixedMinePool = artifacts.require("fixedMinePool");
const minePoolProxy = artifacts.require("fixedMinePoolProxy");
const integratedStake = artifacts.require("integratedStake");
const CFNX = artifacts.require("CFNX");
const { assertion } = require("@openzeppelin/test-helpers/src/expectRevert");
const BN = require("bn.js");
let IERC20 = artifacts.require("IERC20");
let PeriodTime = 90*86400;
contract('integratedStake', function (accounts){
    let FPTA;
    let FPTB;
    let managerA;
    let managerB;
    let FNX;
    let USDC;
    let USDT;
    let cFNX;

    before(async () => {
        FPTA = await IERC20.at("0xB3d71938d085503E52d7eF837C2de8B63fE79203");
        FPTB = await IERC20.at("0xCB678aF010fbd70861b9D59fFec6870541B869b8");
        managerA = await IOptionMgrPoxy.at("0x34F42C54B3b89Bf935FD28D0eE6E451AEA36390B");
        managerB = await IOptionMgrPoxy.at("0x3AC997b6588d22Bd354261389C5Cf88376fA6739");
        FNX= await IERC20.at("0x2287Cd6E8da47CCBdc10B0b7C001e9CB66a436eb");
        USDC= await IERC20.at("0xEc4a5858eF3c1E626c906b0DC3593c491646b651");
        USDT= await IERC20.at("0x2F6902054B0ba3AC54611b3Daf7Ec500dEeEE9cf");
        cFNX = await CFNX.new();
        console.log("cfnx address:" + cFNX.address);
    });
    it('integratedStake stake only USDC', async function () {
        let contracts = await deployMinePool();
        let curPeriod = await contracts[0].getCurrentPeriodID();
        let inputs = {
            usdAddr : [USDC.address],
            amountA : [10000000000],
            fnxAddr : [],
            amountB : [],
            lockedPeriod : 0,
        }
        let checkOut =["10000000000000000000000","0",0,0]
        await testStakeContract(contracts,inputs,checkOut)
    })
    it('integratedStake stake only USDC and Locked', async function () {
        let contracts = await deployMinePool();
        let curPeriod = await contracts[0].getCurrentPeriodID();
        let inputs = {
            usdAddr : [USDC.address],
            amountA : [10000000000],
            fnxAddr : [],
            amountB : [],
            lockedPeriod : 12,
        }
        let checkOut =["10000000000000000000000","0",0,0]
        await testStakeContract(contracts,inputs,checkOut)
    })
    it('integratedStake stake only FNX', async function () {
        let contracts = await deployMinePool();
        let curPeriod = await contracts[0].getCurrentPeriodID();
        let inputs = {
            usdAddr : [],
            amountA : [],
            fnxAddr : [FNX.address],
            amountB : [new BN("100000000000000000000000")],
            lockedPeriod : 0,
        }
        let checkOut =["0","28000000000000000000000",0]
        await testStakeContract(contracts,inputs,checkOut)
    })
    it('integratedStake stake only FNX and locked', async function () {
        let contracts = await deployMinePool();
        let curPeriod = await contracts[0].getCurrentPeriodID();
        let locked = 5;
        let expiraiton = await contracts[0].getPeriodFinishTime(curPeriod.toNumber()+locked-1)
        let inputs = {
            usdAddr : [],
            amountA : [],
            fnxAddr : [FNX.address],
            amountB : [new BN("100000000000000000000000")],
            lockedPeriod : locked,
        }
        let checkOut =["0","28000000000000000000000",curPeriod.toNumber()+locked-1,expiraiton]
        await testStakeContract(contracts,inputs,checkOut)
    })
    it('integratedStake stake USDC and FNX', async function () {
        let contracts = await deployMinePool();
        let curPeriod = await contracts[0].getCurrentPeriodID();
        let inputs = {
            usdAddr : [USDC.address],
            amountA : [10000000000],
            fnxAddr : [FNX.address],
            amountB : [new BN("100000000000000000000000")],
            lockedPeriod : 0,
        }
        let checkOut =["10000000000000000000000","28000000000000000000000",0]
        await testStakeContract(contracts,inputs,checkOut)
    })
    it('integratedStake stake USDC and FNX ,locked', async function () {
        let contracts = await deployMinePool();
        let curPeriod = await contracts[0].getCurrentPeriodID();
        let expiraiton = await contracts[0].getPeriodFinishTime(curPeriod.toNumber()+11)
        let inputs = {
            usdAddr : [USDC.address],
            amountA : [10000000000],
            fnxAddr : [FNX.address],
            amountB : [new BN("100000000000000000000000")],
            lockedPeriod : 12,
        }
        let checkOut =["10000000000000000000000","28000000000000000000000",curPeriod.toNumber()+11,expiraiton.toNumber()]
        await testStakeContract(contracts,inputs,checkOut)
    })
    it('integratedStake stake USDC,USDT and FNX ,locked', async function () {
        let contracts = await deployMinePool();
        let curPeriod = await contracts[0].getCurrentPeriodID();
        let expiraiton = await contracts[0].getPeriodFinishTime(curPeriod.toNumber()+11)
        let inputs = {
            usdAddr : [USDC.address,USDT.address],
            amountA : [10000000000,20000000000],
            fnxAddr : [FNX.address],
            amountB : [new BN("100000000000000000000000")],
            lockedPeriod : 12,
        }
        let checkOut =["30000000000000000000000","28000000000000000000000",curPeriod.toNumber()+11,expiraiton.toNumber()]
        await testStakeContract(contracts,inputs,checkOut)
    })
    it('integratedStake stake only FNX twice', async function () {
        let contracts = await deployMinePool();
        let curPeriod = await contracts[0].getCurrentPeriodID();
        let inputs = {
            usdAddr : [],
            amountA : [],
            fnxAddr : [FNX.address],
            amountB : [new BN("100000000000000000000000")],
            lockedPeriod : 0,
        }
        let checkOut =["0","28000000000000000000000",0]
        await testStakeContract(contracts,inputs,checkOut)
        checkOut =["0","56000000000000000000000",0]
        await testStakeContract(contracts,inputs,checkOut)
    })
    
    it('integratedStake stake USDC then FNX', async function () {
        let contracts = await deployMinePool();
        let curPeriod = await contracts[0].getCurrentPeriodID();
        let inputs = {
            usdAddr : [USDC.address],
            amountA : [10000000000],
            fnxAddr : [],
            amountB : [],
            lockedPeriod : 0,
        }
        let checkOut =["10000000000000000000000","0",0,0]
        await testStakeContract(contracts,inputs,checkOut)
        inputs = {
            usdAddr : [],
            amountA : [],
            fnxAddr : [FNX.address],
            amountB : [new BN("100000000000000000000000")],
            lockedPeriod : 0,
        }
        checkOut =["10000000000000000000000","28000000000000000000000",0]
        await testStakeContract(contracts,inputs,checkOut)
    })
    it('integratedStake stake USDC then FNX，locked', async function () {
        let contracts = await deployMinePool();
        let curPeriod = await contracts[0].getCurrentPeriodID();
        let expiraiton = await contracts[0].getPeriodFinishTime(curPeriod.toNumber()+11)
        let inputs = {
            usdAddr : [USDC.address],
            amountA : [10000000000],
            fnxAddr : [],
            amountB : [],
            lockedPeriod : 0,
        }
        let checkOut =["10000000000000000000000","0",0,0]
        await testStakeContract(contracts,inputs,checkOut)
        inputs = {
            usdAddr : [],
            amountA : [],
            fnxAddr : [FNX.address],
            amountB : [new BN("100000000000000000000000")],
            lockedPeriod : 12,
        }
        checkOut =["10000000000000000000000","28000000000000000000000",curPeriod.toNumber()+11,expiraiton.toNumber()]
        await testStakeContract(contracts,inputs,checkOut)
    })
    it('integratedStake stake FNX then USDC', async function () {
        let contracts = await deployMinePool();
        let curPeriod = await contracts[0].getCurrentPeriodID();
        let inputs = {
            usdAddr : [],
            amountA : [],
            fnxAddr : [FNX.address],
            amountB : [new BN("100000000000000000000000")],
            lockedPeriod : 0,
        }
        let checkOut =["0","28000000000000000000000",0]
        await testStakeContract(contracts,inputs,checkOut)
        inputs = {

            usdAddr : [USDC.address],
            amountA : [10000000000],
            fnxAddr : [],
            amountB : [],
            lockedPeriod : 0,
        }
        checkOut =["10000000000000000000000","28000000000000000000000",0]
        await testStakeContract(contracts,inputs,checkOut)
    })
    it('integratedStake stake FNX then USDC,locked', async function () {
        let contracts = await deployMinePool();
        let curPeriod = await contracts[0].getCurrentPeriodID();
        let expiraiton = await contracts[0].getPeriodFinishTime(curPeriod.toNumber()+11)
        let inputs = {
            usdAddr : [],
            amountA : [],
            fnxAddr : [FNX.address],
            amountB : [new BN("100000000000000000000000")],
            lockedPeriod : 0,
        }
        let checkOut =["0","28000000000000000000000",0]
        await testStakeContract(contracts,inputs,checkOut)
        inputs = {

            usdAddr : [USDC.address],
            amountA : [10000000000],
            fnxAddr : [],
            amountB : [],
            lockedPeriod : 12,
        }
        checkOut =["10000000000000000000000","28000000000000000000000",curPeriod.toNumber()+11,expiraiton.toNumber()]
        await testStakeContract(contracts,inputs,checkOut)
    })
    it('integratedStake stake USDC,USDT and FNX ,add locked', async function () {
        let contracts = await deployMinePool();
        let curPeriod = await contracts[0].getCurrentPeriodID();
        let expiraiton = await contracts[0].getPeriodFinishTime(curPeriod.toNumber()+4)
        let inputs = {
            usdAddr : [USDC.address,USDT.address],
            amountA : [10000000000,20000000000],
            fnxAddr : [FNX.address],
            amountB : [new BN("100000000000000000000000")],
            lockedPeriod : 5,
        }
        let checkOut =["30000000000000000000000","28000000000000000000000",curPeriod.toNumber()+4,expiraiton.toNumber()]
        await testStakeContract(contracts,inputs,checkOut)
        expiraiton = await contracts[0].getPeriodFinishTime(curPeriod.toNumber()+11)
        inputs.lockedPeriod = 12
        checkOut =["60000000000000000000000","56000000000000000000000",curPeriod.toNumber()+11,expiraiton.toNumber()]
        await testStakeContract(contracts,inputs,checkOut)
    })
    it('integratedStake stake USDC,USDT and FNX ,less locked', async function () {
        let contracts = await deployMinePool();
        let curPeriod = await contracts[0].getCurrentPeriodID();
        let expiraiton = await contracts[0].getPeriodFinishTime(curPeriod.toNumber()+11)
        let inputs = {
            usdAddr : [USDC.address,USDT.address],
            amountA : [10000000000,20000000000],
            fnxAddr : [FNX.address],
            amountB : [new BN("100000000000000000000000")],
            lockedPeriod : 12,
        }
        let checkOut =["30000000000000000000000","28000000000000000000000",curPeriod.toNumber()+11,expiraiton.toNumber()]
        await testStakeContract(contracts,inputs,checkOut)
        inputs.lockedPeriod = 5
        await testViolation("changing FPTB locked period input less period",async function(){
            await testStakeContract(contracts,inputs,checkOut)
        })
        inputs.lockedPeriod = 15
        await testViolation("changing FPTB locked period input error period",async function(){
            await testStakeContract(contracts,inputs,checkOut)
        })
    })
    it('integratedStake stake USDC,USDT and FNX ,add locked, unstaked', async function () {
        let contracts = await deployMinePool();
        let curPeriod = await contracts[0].getCurrentPeriodID();
        let expiraiton = await contracts[0].getPeriodFinishTime(curPeriod.toNumber()+4)
        let inputs = {
            usdAddr : [USDC.address,USDT.address],
            amountA : [10000000000,20000000000],
            fnxAddr : [FNX.address],
            amountB : [new BN("100000000000000000000000")],
            lockedPeriod : 5,
        }
        let checkOut =["30000000000000000000000","28000000000000000000000",curPeriod.toNumber()+4,expiraiton.toNumber()]
        await testStakeContract(contracts,inputs,checkOut)
        expiraiton = await contracts[0].getPeriodFinishTime(curPeriod.toNumber()+11)
        inputs.lockedPeriod = 12
        checkOut =["60000000000000000000000","56000000000000000000000",curPeriod.toNumber()+11,expiraiton.toNumber()]
        await testStakeContract(contracts,inputs,checkOut)
        await contracts[0].unstakeFPTA(new BN("60000000000000000000000"));
    })
    async function testStakeContract (contracts,inputs,checkOut) {
        for (var i=0;i<inputs.usdAddr.length;i++){
            erc20 = await IERC20.at(inputs.usdAddr[i]);
            await erc20.approve(contracts[1].address,inputs.amountA[i])
        }
        for (var i=0;i<inputs.fnxAddr.length;i++){
            erc20 = await IERC20.at(inputs.fnxAddr[i]);
            await erc20.approve(contracts[1].address,inputs.amountB[i])
        }
        await contracts[1].stake(inputs.usdAddr,inputs.amountA,inputs.fnxAddr,inputs.amountB,inputs.lockedPeriod);

        let balanceA = await contracts[0].getUserFPTABalance(accounts[0]);
        assert.equal(balanceA.toString(),checkOut[0],"User balanceA error")
        let balanceB = await contracts[0].getUserFPTBBalance(accounts[0]);
        assert.equal(balanceB.toString(),checkOut[1],"User balanceB error")
        let maxId = await contracts[0].getUserMaxPeriodId(accounts[0]);
        assert.equal(maxId.toNumber(),checkOut[2],"User Max periodID error")
        let expired = await contracts[0].getUserExpired(accounts[0]);
        if (checkOut.length > 3){
            assert.equal(expired.toNumber(),checkOut[3],"User expiration error")
        }else{
            assert(expired.toNumber()>0,"User expiration error")
            console.log("User expiration : ",expired.toNumber())
        }
    }
    async function deployMinePool () {
        let startTime = 10000000;
        let minePoolImpl = await fixedMinePool.new(FPTA.address,FPTB.address,startTime);
        let minePool = await minePoolProxy.new(minePoolImpl.address,FPTA.address,FPTB.address,startTime);
        let stakeInst = await integratedStake.new(FPTA.address,FPTB.address,managerA.address,managerB.address,minePool.address)
        minePool.setOperator(2,stakeInst.address)
        return [minePool,stakeInst]
    }
})
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