const BigNumber = require('bignumber.js');

function calculateDistributionBN(fptA,fptB){
    let distri = fptA.plus(fptB);
    fptB = fptB.multipliedBy(10);
    if (fptA.gt(fptB)){
        distri = distri.plus(fptB.multipliedBy(20));
    }else{
        distri = distri.plus(fptA.multipliedBy(20));
    }
    return distri.multipliedBy(1000);
}
function calculateBoostRatio(lockPeriodNum){
    if(lockPeriodNum == 0){
        return 1;
    }
    return lockPeriodNum+4;
}
// async function getMineInfo(contracts,account){
//     let fptA = await contracts.minePool.getUserFPTABalance(account);
//     let fptB = await contracts.minePool.getUserFPTBBalance(account);
//     let totalDistribution = await contracts.minePool.getTotalDistribution();
//     let mineInfo = await contracts.minePool.getMineInfo(contracts.MINE.address);
//     return {
//         FPTA : fptA,
//         FPTB : fptB,
//         TotalDistri : totalDistribution,
//         MineAmount : mineInfo[0],
//         MineInterval : mineInfo[1]
//     }
// }

function UserbaseMineAmount(mineInfo,newFPTA,newFPTB){
    let year = new BigNumber(31536000);
    let oldDistriBN = calculateDistributionBN(mineInfo.FPTA,mineInfo.FPTB);
    let distriBN = calculateDistributionBN(mineInfo.FPTA.plus(newFPTA),mineInfo.FPTB.plus(newFPTB));
    if (mineInfo.MineInterval.eq(0)){
        return 0;
    }
    if (mineInfo.TotalDistri.gt(0)){
        
        return mineInfo.MineAmount.multipliedBy(year).multipliedBy(distriBN).div(mineInfo.TotalDistri.minus(oldDistriBN).plus(distriBN)).div(mineInfo.MineInterval);
    }else{
        return mineInfo.MineAmount.multipliedBy(year).div(mineInfo.MineInterval);
    }
}

function UserMineAmount(mineInfo,newFPTA,newFPTB,lockPeriodNum){
    console.log('UserMineAmount!!!!!', JSON.stringify(mineInfo, null, 2), newFPTA.toString(), newFPTB.toString(), lockPeriodNum);
    let baseMine = UserbaseMineAmount(mineInfo,newFPTA,newFPTB);
    return baseMine.multipliedBy(calculateBoostRatio(lockPeriodNum));
}
let mineInfo = {
    FPTA : new BigNumber(792174.200870282127818382),
    FPTB : new BigNumber(1186610.228273614087623044),
    TotalDistri :new BigNumber(17822268446.549538771809066),
    MineAmount : new BigNumber(0.231481481481481481),
    MineInterval :new BigNumber(1)
}
let allMine = UserMineAmount(mineInfo,0,0,12);
console.log(allMine.toString());