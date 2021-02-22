const { time, expectEvent} = require("@openzeppelin/test-helpers")
let utils = require('../converterTest/utils.js');

let colpool = artifacts.require("mockColPool");
let minepool = artifacts.require("mockMine");
let fptb = artifacts.require("mockToken");
let airdropvault =  artifacts.require("AirDropVault");
let airdropProxy = artifacts.require("AirDropVaultProxy");

const BN = require("bn.js");
const assert = require('assert');

const ONE_HOUR = 60*60;
const ONE_DAY = ONE_HOUR * 24;
const ONE_MONTH = 30 * ONE_DAY;

contract('TokenConverter', function (accounts) {
    let fnxAmount = new BN("50");
    let fnxPerPerson = new BN("2");
    let minThredhold = new BN("1");
    let timeSpan = 3600;
    let userCount = 10;
    let maxWhiteListClaim = new BN("20");
    let maxFreeClaim = new BN("20");
    let fptbInst;
    let fnxInst;
    let curvInst;
    let cfnxInst;

    let colpoolInst;
    let minepoolInst;

    let airdropVaultInst;
    let airdropproxyInst;


    before(async () => {
        fptbInst = await fptb.new();
        console.log("fptb address:" + fptbInst.address);

        colpoolInst = await colpool.new();
        console.log("colpool address:" + colpoolInst.address);

        minepoolInst = await minepool.new();
        console.log("minepool address:" + minepoolInst.address);

        fnxInst = await fptb.new();
        console.log("fnx address:" + fnxInst.address);

        curvInst = await fptb.new();
        console.log("curv address:" + curvInst.address);

        cfnxInst = await fptb.new();
        console.log("fnx address:" + fnxInst.address);

        let tx = await colpoolInst.initialize(fptbInst.address);
        assert.equal(tx.receipt.status,true);

        tx = await minepoolInst.initialize(fptbInst.address);
        assert.equal(tx.receipt.status,true);

        airdropVaultInst = await airdropvault.new();
        console.log("airdropvault address:" + airdropVaultInst.address);

        airdropproxyInst = await airdropProxy.new(airdropVaultInst.address);
        console.log("airdropProxy address:" + airdropproxyInst.address);

        tx = await airdropproxyInst.setOperator(1,accounts[0]);
        assert.equal(tx.receipt.status,true);

        tx = await airdropproxyInst.setTokenList([curvInst.address],[web3.utils.toWei(minThredhold)]);
        assert.equal(tx.receipt.status,true);

        let i = 0;
        for(i=0;i<userCount;i++) {
            tx = await curvInst.mint(accounts[i],web3.utils.toWei(fnxPerPerson));
            assert.equal(tx.receipt.status,true);
        }

        let lastedToBlkNum = await web3.eth.getBlockNumber();
        let lastblock = await  web3.eth.getBlock(lastedToBlkNum);
        // function initAirdrop( address /*_optionColPool*/,
        //                       address /*_minePool*/,
        //                       address /*_fnxToken*/,
        //                       address /*_ftpbToken*/,
        //                       uint256 /*_claimBeginTime*/,
        //                       uint256 /*_claimEndTime*/,
        //                       uint256 /*_fnxPerFreeClaimUser*/,
        //                       uint256 /*_minBalForFreeClaim*/,
        //                       uint256 /*_maxFreeFnxAirDrop*/,
        //                       uint256 /*_maxWhiteListFnxAirDrop*/)
        tx = await airdropproxyInst.initAirdrop(
                    colpoolInst.address,
                    minepoolInst.address,
                    fnxInst.address,
                    fptbInst.address,
                    lastblock.timestamp,
                    lastblock.timestamp + timeSpan,
                    web3.utils.toWei(fnxPerPerson),
                    web3.utils.toWei(maxFreeClaim),
                    web3.utils.toWei(maxWhiteListClaim));

        assert.equal(tx.receipt.status,true);

        tx = await fnxInst.mint(airdropproxyInst.address,web3.utils.toWei(fnxAmount));
        assert.equal(tx.receipt.status,true);

        let users = [];
        let usersFnxNum = [];
        for(i=0;i<userCount;i++) {
            users.push(accounts[i]);
            usersFnxNum.push(web3.utils.toWei(fnxPerPerson));
            //console.log(usersFnxNum[i])
        }
        tx = await airdropproxyInst.setWhiteList(users,usersFnxNum);
        assert.equal(tx.receipt.status,true);
    });

    it('10 users claim adirdrop according to whitelist', async function () {
        let i =0;
        for(;i<userCount;i++) {
            console.log("user"+i +" airdrop")
            let beforeFnxAirdropproxy = await fnxInst.balanceOf(airdropproxyInst.address);
            let beforeLockedFtpUser =  await minepoolInst.lockedBalances(accounts[i]);
            let beforeFptbMinepool = await fptbInst.balanceOf(minepoolInst.address);

            let tx = await airdropproxyInst.whitelistClaim({from:accounts[i]});
            console.log(tx)
            return;
            assert.equal(tx.receipt.status,true);

            let afterFnxAirdropproxy = await fnxInst.balanceOf(airdropproxyInst.address);
            let afterLockedFtpUser =  await minepoolInst.lockedBalances(accounts[i]);
            let afterFptbMinepool = await fptbInst.balanceOf(minepoolInst.address);

            let diff = web3.utils.fromWei(new BN(beforeFnxAirdropproxy)) - web3.utils.fromWei(new BN(afterFnxAirdropproxy));
            console.log("diff proxy fnx=" + diff);

            diff = web3.utils.fromWei(new BN(afterLockedFtpUser)) - web3.utils.fromWei(new BN(beforeLockedFtpUser));
            console.log("diff mine user locked fptb=" + diff);
            assert.equal(diff,fnxPerPerson.toNumber());

            diff = web3.utils.fromWei(new BN(afterFptbMinepool)) - web3.utils.fromWei(new BN(beforeFptbMinepool));
            console.log("diff mine pool diff fptb=" + diff);
            assert.equal(diff,fnxPerPerson.toNumber());
          }
    })
    return
    it('10 users claim adirdrop in free claim ways', async function () {
        let i =0;
        for(;i<userCount;i++) {
            console.log("user"+i +" airdrop")
            let beforeFnxAirdropproxy = await fnxInst.balanceOf(airdropproxyInst.address);
            let beforeLockedFtpUser =  await minepoolInst.lockedBalances(accounts[i]);
            let beforeFptbMinepool = await fptbInst.balanceOf(minepoolInst.address);

            let tx = await airdropproxyInst.freeClaim(curvInst.address,{from:accounts[i]});
            assert.equal(tx.receipt.status,true);

            let afterFnxAirdropproxy = await fnxInst.balanceOf(airdropproxyInst.address);
            let afterLockedFtpUser =  await minepoolInst.lockedBalances(accounts[i]);
            let afterFptbMinepool = await fptbInst.balanceOf(minepoolInst.address);

            let diff = web3.utils.fromWei(new BN(beforeFnxAirdropproxy)) - web3.utils.fromWei(new BN(afterFnxAirdropproxy));
            console.log("diff proxy fnx=" + diff);

            diff = web3.utils.fromWei(new BN(afterLockedFtpUser)) - web3.utils.fromWei(new BN(beforeLockedFtpUser));
            console.log("diff mine user locked fptb=" + diff);
            assert.equal(diff,fnxPerPerson.toNumber());

            diff = web3.utils.fromWei(new BN(afterFptbMinepool)) - web3.utils.fromWei(new BN(beforeFptbMinepool));
            console.log("diff mine pool diff fptb=" + diff);
            assert.equal(diff,fnxPerPerson.toNumber());
        }
    })


    it('get back left fnx', async function () {
        let beforeFnxAirdropproxy = await fnxInst.balanceOf(airdropproxyInst.address);
        let beforeUser7Fnx =  await fnxInst.balanceOf(accounts[7]);
        let tx = await airdropproxyInst.getbackLeftFnx(accounts[7]);
        assert.equal(tx.receipt.status,true);
        let afterFnxAirdropproxy = await fnxInst.balanceOf(airdropproxyInst.address);
        let afterUser7Fnx =  await fnxInst.balanceOf(accounts[7]);

        let diff = web3.utils.fromWei(new BN(beforeFnxAirdropproxy)) - web3.utils.fromWei(new BN(afterFnxAirdropproxy));
        console.log("diff proxy fnx=" + diff);
        assert.equal(diff,10);

        diff = web3.utils.fromWei(new BN(afterUser7Fnx)) - web3.utils.fromWei(new BN(beforeUser7Fnx));
        console.log("diff proxy fnx=" + diff);
        assert.equal(diff,10);
    })

    it('added sushi mine and user get sushi mine in one inteval', async function () {
        let lastedToBlkNum = await web3.eth.getBlockNumber();
        let lastblock = await  web3.eth.getBlock(lastedToBlkNum);
        //initSushiMine(address _cfnxToken,uint256 _sushiMineStartTime,uint256 _sushimineInterval)
        let tx = await airdropproxyInst.initSushiMine(cfnxInst.address,lastblock.timestamp,timeSpan);
        assert.equal(tx.receipt.status,true);

        tx = await cfnxInst.mint(airdropproxyInst.address,web3.utils.toWei(fnxAmount));
        assert.equal(tx.receipt.status,true);

        let users = [];
        let usersFnxNum = [];
        let i = 0;
        for(i=0;i<userCount;i++) {
            users.push(accounts[i]);
            usersFnxNum.push(web3.utils.toWei(fnxPerPerson));
            //console.log(usersFnxNum[i])
        }
        tx = await airdropproxyInst.setSushiMineList(users,usersFnxNum);
        assert.equal(tx.receipt.status,true);

        i =0;
        for(;i<userCount;i++) {
            console.log("user"+i +" airdrop")
            let beforeCFnxAirdropproxy = await cfnxInst.balanceOf(airdropproxyInst.address);
            let beforeCfnxUser =  await cfnxInst.balanceOf(accounts[i]);

            let tx = await airdropproxyInst.sushiMineClaim({from:accounts[i]});
            assert.equal(tx.receipt.status,true);

            let afterCFnxAirdropproxy = await cfnxInst.balanceOf(airdropproxyInst.address);
            let afterCfnxUser =  await cfnxInst.balanceOf(accounts[i]);

            let diff = web3.utils.fromWei(new BN(beforeCFnxAirdropproxy)) - web3.utils.fromWei(new BN(afterCFnxAirdropproxy));
            console.log("diff proxy fnx=" + diff);

            diff = web3.utils.fromWei(new BN(afterCfnxUser)) - web3.utils.fromWei(new BN(beforeCfnxUser));
            console.log("diff mine user CFNX=" + diff);
            assert.equal(diff,fnxPerPerson.toNumber());
        }
    });

    it('added sushi mine and user get sushi mine after several interval', async function () {
       await time.increase(timeSpan + 2);
       let tx = await cfnxInst.mint(airdropproxyInst.address,web3.utils.toWei(fnxAmount.mul(new BN(3))));
        assert.equal(tx.receipt.status,true);

        let users = [];
        let usersFnxNum = [];
        let i = 0;
        for(i=0;i<userCount;i++) {
            users.push(accounts[i]);
            usersFnxNum.push(web3.utils.toWei(fnxPerPerson));
            //console.log(usersFnxNum[i])
        }
        tx = await airdropproxyInst.setSushiMineList(users,usersFnxNum);
        assert.equal(tx.receipt.status,true);

        await time.increase(timeSpan + 2);
        tx = await  airdropproxyInst.setSushiMineList(users,usersFnxNum);
        assert.equal(tx.receipt.status,true);

        await time.increase(timeSpan + 2);
        tx = await  airdropproxyInst.setSushiMineList(users,usersFnxNum);
        assert.equal(tx.receipt.status,true);

        i =0;
        for(;i<userCount;i++) {
            console.log("user"+i +" airdrop")
            let beforeCFnxAirdropproxy = await cfnxInst.balanceOf(airdropproxyInst.address);
            let beforeCfnxUser =  await cfnxInst.balanceOf(accounts[i]);

            let tx = await airdropproxyInst.sushiMineClaim({from:accounts[i]});
            assert.equal(tx.receipt.status,true);

            let afterCFnxAirdropproxy = await cfnxInst.balanceOf(airdropproxyInst.address);
            let afterCfnxUser =  await cfnxInst.balanceOf(accounts[i]);

            let diff = web3.utils.fromWei(new BN(beforeCFnxAirdropproxy)) - web3.utils.fromWei(new BN(afterCFnxAirdropproxy));
            console.log("diff proxy fnx=" + diff);

            diff = web3.utils.fromWei(new BN(afterCfnxUser)) - web3.utils.fromWei(new BN(beforeCfnxUser));
            console.log("diff mine user CFNX=" + diff);
            assert.equal(diff,fnxPerPerson.toNumber()*3);
        }
    });


})