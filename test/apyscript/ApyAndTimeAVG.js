var User = require('./user.js');

var express = require('express');
var app = express();
var Web3 = require('web3');
var web3 = new Web3(new Web3.providers.HttpProvider("https://rinkeby.infura.io/v3/75c431806c0d49ee9868d4fdcef025bd"));
//var web3 = new Web3(new Web3.providers.HttpProvider("https://mainnet.infura.io/v3/75c431806c0d49ee9868d4fdcef025bd"));

const BN = require("bn.js");
var { abi } = require('./fixedMinePoolProxy.json');
var minepoolabi = abi;

var { abi } = require('./FNXOracle.json');
var oracleabi = abi;

var { abi } = require('./ManagerProxy.json');
var opitonabi = abi;

var { abi } = require('./FPTCoin.json');
var fptbabi = abi;
var schedule = require("node-schedule");

const FNXADDRESS = '0xacc919c0c784404108723c39e754961066ab24e0';
const minepooladdress = '0xacc919c0c784404108723c39e754961066ab24e0';
const oracleaddress = '0xacc919c0c784404108723c39e754961066ab24e0';
const optionUsdcAddress = '0xacc919c0c784404108723c39e754961066ab24e0';
const optionFnxAddress = '0xacc919c0c784404108723c39e754961066ab24e0';

const fnxaddress = '0xacc919c0c784404108723c39e754961066ab24e0';
const ftpbaddress = '0xacc919c0c784404108723c39e754961066ab24e0';

const minepool = new web3.eth.Contract(minepoolabi, minepooladdress);
const oracle = new web3.eth.Contract(oracleabi, oracleaddress);
const opitonUsdc = new web3.eth.Contract(opitonabi, optionUsdcAddress);
const opitonFnx = new web3.eth.Contract(opitonabi, optionFnxAddress);

const fptb = new web3.eth.Contract(fptbabi, ftpbaddress);
const initBlkNum = 7859068;

var stakerMap = new Map();
var previousBlkNum = 0;
var totalIdx = 0;
var resultMap = new Map();

async function loadFromDB() {
    let gotblk = await User.getBlockNum();
    console.log("get block number");
    console.log(gotblk);
    if(gotblk!=null) {
        previousBlkNum = gotblk.blocknumber;
    }

    let all = await User.findAll();
    if(all != null) {
        let i = 0;
        for (i = 0; i < all.length; i++) {
            stakerMap[all[i].address] = all[i].value;
        }
    }

    console.log(stakerMap);
}

async function getStakers(blkFrom,blkTo) {
    let i = 0;
    console.log(blkFrom,blkTo);
    try {
        //  event StakeFPTA(address indexed account,uint256 amount);
        const StakeFPTAEvent = await minepool.getPastEvents('StakeFPTA', {fromBlock: blkFrom, toBlock: blkTo});
        for (i=0; i < StakeFPTAEvent.length; i++) {
            let account = StakeFPTAEvent[i].returnValues.account;
            //console.log(account);
            stakerMap[account] = "OK";
            User.save(account,stakerMap[account]);
        }
    }catch (e) {
        console.error(e)
    }

    try {
        //event StakeFPTB(address indexed account,uint256 amount,uint256 lockedPeriod);
        const StakeFPTBEvent = await minepool.getPastEvents('StakeFPTB', {fromBlock: blkFrom, toBlock: blkTo});
        for (i=0; i < StakeFPTBEvent.length; i++) {
            let account = StakeFPTBEvent[i].returnValues.account;
            //console.log(account);
            if (stakerMap[account] == undefined) {
                stakerMap[account] = "OK";
                User.save(account,stakerMap[account]);
            }
        }
    }catch (e) {
        console.error(e)
    }

    try {
        //event LockAirDrop(address indexed from,address indexed recieptor,uint256 amount);
        const LockAirDropEvent = await minepool.getPastEvents('LockAirDrop', {fromBlock: blkFrom, toBlock: blkTo});
        for (i=0; i < LockAirDropEvent.length; i++) {
            let account = LockAirDropEvent[i].returnValues.recieptor;
           // console.log(account);
            if (stakerMap[account] == undefined) {
                stakerMap[account] = "OK";
                User.save(account,stakerMap[account]);
            }
        }
    }catch (e) {
        console.error(e)
    }

    User.saveBlockNum(blkTo);
    console.log("GET STAKERS END");
    //console.log(stakerMap);

    // for (var key in stakerMap) {
    //   // User.save(key,stakerMap[key]);
    // }

    // for (var key in stakerMap) {
    //     result = await User.find(key);
    //     //console.log(result);
    // }

}

async function calculate() {
   console.log("calculation begin....");
   try{
        let minapy = 10000;
        let maxapy = 0;
        for (var key in stakerMap) {
            let mineofyear = await minepool.methods.getUserCurrentAPY(key,fnxaddress).call();
            let FTPA = web3.utils.fromWei(await minepool.methods.getUserFPTABalance(key).call());
            let FTPB = web3.utils.fromWei(await minepool.methods.getUserFPTBBalance(key).call());
            let fnxprice = await oracle.methods.getPrice(FNXADDRESS).call();
            let fptaprice = await opitonUsdc.methods.getTokenNetworth().call();
            let fptbprice = await opitonFnx.methods.getTokenNetworth().call();

            console.log(mineofyear,FTPA,FTPB,fnxprice,fptaprice,fptbprice);
            let denominater = FTPA*fptaprice + FTPB*fptbprice;
            if(denominater==0) {
                continue;
            }
            let apy = ((mineofyear*fnxprice)*100/denominater).toFixed(2);

            if (apy>maxapy) {
                maxapy = apy;
            }

            if(apy<minapy) {
                minapy = apy
            }
        }

        let sumPeriodMulTime = new BN(0);
        let totalFptb = web3.utils.fromWei(new BN(await fptb.methods.balanceOf(minepooladdress).call()));
        let lastedToBlkNum = await web3.eth.getBlockNumber();

        let block = await web3.eth.getBlock(lastedToBlkNum);
       // console.log(block);
        let nowTime = block.timestamp;
        for (var key in stakerMap) {

            let maxperiodid = await minepool.methods.getUserMaxPeriodId(key).call();
            let userexpired = await minepool.methods.getUserExpired(key).call();
            let balance = web3.utils.fromWei(await minepool.methods.getUserFPTBBalance(key).call());
            let diffLockTime = 0;
            if (userexpired>nowTime) {
                diffLockTime = userexpired - nowTime;
                sumPeriodMulTime = sumPeriodMulTime.add(new BN(diffLockTime*balance));
            }

            console.log(key,userexpired,balance,nowTime,userexpired);
        }

        console.log(totalFptb,sumPeriodMulTime.toString());

        let avgLockTime = 0;
        if(totalFptb>0) {
           avgLockTime = sumPeriodMulTime / totalFptb;
        }

        console.log(minapy,maxapy,avgLockTime);
        resultMap[totalIdx] = {"minapy":minapy,"maxapy":maxapy,"avglocktime":avgLockTime};
        console.log(resultMap[totalIdx]);
        totalIdx++;

    } catch (e) {
        console.error(e)
    }
}

async function initScan() {
    console.log("init scan...")

    loadFromDB();

    let lastedToBlkNum = await web3.eth.getBlockNumber();
    if(previousBlkNum == 0) {
        await getStakers(initBlkNum, lastedToBlkNum);
    } else {
        await getStakers(previousBlkNum, lastedToBlkNum);
    }

    previousBlkNum = lastedToBlkNum;
}

async function task() {
    console.log("task running...");
    let lastedToBlkNum = await web3.eth.getBlockNumber();
    await getStakers(previousBlkNum,lastedToBlkNum);
    previousBlkNum = lastedToBlkNum;
    await calculate(stakerMap);

    //console.log(resultMap[totalIdx-1]);
    console.log("task end...");
}

async function setupTask() {
    await initScan();
  //  await calculate();
    var rule = new schedule.RecurrenceRule();
    rule.second = 5;
    var j = schedule.scheduleJob(rule, task);
}

setupTask();

app.get('/getApyAndAvgLockTime', function (req, res) {
    console.log(resultMap[totalIdx-1]);
    res.send(resultMap[totalIdx-1]);

    return;
});

var server = app.listen(8081, function () {
    var host = server.address().address
    var port = server.address().port
    console.log("server start http://%s:%s", host, port)
});




