pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * FinNexus
 * Copyright (C) 2020 FinNexus Options Protocol
 */
import "../modules/SafeMath.sol";
import "./fixedMinePoolData.sol";
import "../ERC20/IERC20.sol";
import "../ERC20/safeErc20.sol";
/**
 * @title FNX period mine pool.
 * @dev A smart-contract which distribute some mine coins when user stake FPT-A and FPT-B coins.
 *
 */
contract fixedMinePool is fixedMinePoolData {
    using SafeMath for uint256;
    /**
     * @dev constructor.
     * @param FPTA FPT-A coin's address,staking coin
     * @param FPTB FPT-B coin's address,staking coin
     * @param startTime the start time when this mine pool begin.
     */
    constructor(address FPTA,address FPTB,uint256 startTime)public{
        _FPTA = FPTA;
        _FPTB = FPTB;
        _startTime = startTime;
        initialize();
    }
    /**
     * @dev default function for foundation input miner coins.
     */
    function()external payable{

    }
    function update()public onlyOwner{
        initialize();
    }
    /**
     * @dev initial function when the proxy contract deployed.
     */
    function initialize() initializer public {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
        _flexibleExpired = 7 days;
        periodWeights = [uint256(1600),uint256(3200),uint256(5000),uint256(5300),uint256(5600),uint256(6000)];
    }

    function getFlexibleExpired()public view returns(uint256){
        return _flexibleExpired;
    }
    function setFlexibleExpired(uint256 expired)public onlyOwner{
        _flexibleExpired = expired;
    }
    /**
     * @dev setting function.
     * @param FPTA FPT-A coin's address,staking coin
     * @param FPTB FPT-B coin's address,staking coin
     * @param startTime the start time when this mine pool begin.
     */
    function setAddresses(address FPTA,address FPTB,uint256 startTime) public onlyOwner {
        _FPTA = FPTA;
        _FPTB = FPTB;
        _startTime = startTime;
    }
    /**
     * @dev getting function. Retrieve FPT-A coin's address
     */
    function getFPTAAddress()public view returns (address) {
        return _FPTA;
    }
    /**
     * @dev getting function. Retrieve FPT-B coin's address
     */
    function getFPTBAddress()public view returns (address) {
        return _FPTB;
    }
    /**
     * @dev getting function. Retrieve mine pool's start time.
     */
    function getStartTime()public view returns (uint256) {
        return _startTime;
    }
    /**
     * @dev getting current mine period ID.
     */
    function getCurrentPeriodID()public view returns (uint256) {
        return getPeriodIndex(currentTime());
    }
    /**
     * @dev getting user's staking FPT-A balance.
     * @param account user's account
     */
    function getUserFPTABalance(address account)public view returns (uint256) {
        return userInfoMap[account]._FPTABalance;
    }
    /**
     * @dev getting user's staking FPT-B balance.
     * @param account user's account
     */
    function getUserFPTBBalance(address account)public view returns (uint256) {
        return userInfoMap[account]._FPTBBalance;
    }
    /**
     * @dev getting user's maximium locked period ID.
     * @param account user's account
     */
    function getUserMaxPeriodId(address account)public view returns (uint256) {
        return userInfoMap[account].maxPeriodID;
    }
    /**
     * @dev getting user's locked expired time. After this time user can unstake FPTB coins.
     * @param account user's account
     */
    function getUserExpired(address account)public view returns (uint256) {
        return userInfoMap[account].lockedExpired;
    }
    /**
     * @dev getting whole pool's mine production weight ratio.
     *      Real mine production equals base mine production multiply weight ratio.
     */
    function getMineWeightRatio()public view returns (uint256) {
        if(totalDistribution > 0) {
            return getweightDistribution(getPeriodIndex(currentTime()))*1000/totalDistribution;
        }else{
            return 1000;
        }
    }
    /**
     * @dev getting whole pool's mine shared distribution. All these distributions will share base mine production.
     */
    function getTotalDistribution() public view returns (uint256){
        return totalDistribution;
    }
    /**
     * @dev foundation redeem out mine coins.
     * @param mineCoin mineCoin address
     * @param amount redeem amount.
     */
    function redeemOut(address mineCoin,uint256 amount)public onlyOwner{
        _redeem(msg.sender,mineCoin,amount);
    }
    /**
     * @dev An auxiliary foundation which transter amount mine coins to recieptor.
     * @param recieptor recieptor recieptor's account.
     * @param mineCoin mineCoin address
     * @param amount redeem amount.
     */
    function _redeem(address payable recieptor,address mineCoin,uint256 amount) internal{
        if (mineCoin == address(0)){
            recieptor.transfer(amount);
        }else{
            IERC20 token = IERC20(mineCoin);
            uint256 preBalance = token.balanceOf(address(this));
            SafeERC20.safeTransfer(token,recieptor,amount);
//            token.transfer(recieptor,amount);
            uint256 afterBalance = token.balanceOf(address(this));
            require(preBalance - afterBalance == amount,"settlement token transfer error!");
        }
    }
    /**
     * @dev retrieve total distributed mine coins.
     * @param mineCoin mineCoin address
     */
    function getTotalMined(address mineCoin)public view returns(uint256){
        return mineInfoMap[mineCoin].totalMinedCoin.add(_getLatestMined(mineCoin));
    }
    /**
     * @dev retrieve minecoin distributed informations.
     * @param mineCoin mineCoin address
     * @return distributed amount and distributed time interval.
     */
    function getMineInfo(address mineCoin)public view returns(uint256,uint256){
        return (mineInfoMap[mineCoin].mineAmount,mineInfoMap[mineCoin].mineInterval);
    }
    /**
     * @dev retrieve user's mine balance.
     * @param account user's account
     * @param mineCoin mineCoin address
     */
    function getMinerBalance(address account,address mineCoin)public view returns(uint256){
        return userInfoMap[account].minerBalances[mineCoin].add(_getUserLatestMined(mineCoin,account));
    }
    /**
     * @dev Set mineCoin mine info, only foundation owner can invoked.
     * @param mineCoin mineCoin address
     * @param _mineAmount mineCoin distributed amount
     * @param _mineInterval mineCoin distributied time interval
     */
    function setMineCoinInfo(address mineCoin,uint256 _mineAmount,uint256 _mineInterval)public onlyOwner {
        require(_mineAmount<1e30,"input mine amount is too large");
        require(_mineInterval>0,"input mine Interval must larger than zero");
        _mineSettlement(mineCoin);
        mineInfoMap[mineCoin].mineAmount = _mineAmount;
        mineInfoMap[mineCoin].mineInterval = _mineInterval;
        if (mineInfoMap[mineCoin].startPeriod == 0){
            mineInfoMap[mineCoin].startPeriod = getPeriodIndex(currentTime());
        }
        addWhiteList(mineCoin);
    }

    /**
     * @dev user redeem mine rewards.
     * @param mineCoin mine coin address
     * @param amount redeem amount.
     */
    function redeemMinerCoin(address mineCoin,uint256 amount)public payable nonReentrant notHalted {
        _mineSettlement(mineCoin);
        _settleUserMine(mineCoin,msg.sender);
        _redeemMineCoin(mineCoin,msg.sender,amount);
    }
    /**
     * @dev subfunction for user redeem mine rewards.
     * @param mineCoin mine coin address
     * @param recieptor recieptor's account
     * @param amount redeem amount.
     */
    function _redeemMineCoin(address mineCoin,address payable recieptor,uint256 amount) internal {
        require (amount > 0,"input amount must more than zero!");
        userInfoMap[recieptor].minerBalances[mineCoin] = 
            userInfoMap[recieptor].minerBalances[mineCoin].sub(amount);

        //collect fees for mine
        if(_fnxFeeRatio!=0) {
            amount = collectFee(mineCoin,amount);
        }

        _redeem(recieptor,mineCoin,amount);
        emit RedeemMineCoin(recieptor,mineCoin,amount);
    }

    /**
     * @dev settle all mine coin.
     */    
    function _mineSettlementAll()internal{
        uint256 addrLen = whiteList.length;
        for(uint256 i=0;i<addrLen;i++){
            _mineSettlement(whiteList[i]);
        }
    }
    /**
     * @dev convert timestamp to period ID.
     * @param _time timestamp. 
     */ 
    function getPeriodIndex(uint256 _time) public view returns (uint256) {
        if (_time<_startTime){
            return 0;
        }
        return _time.sub(_startTime).div(_period)+1;
    }
    /**
     * @dev convert period ID to period's finish timestamp.
     * @param periodID period ID. 
     */
    function getPeriodFinishTime(uint256 periodID)public view returns (uint256) {
        return periodID.mul(_period).add(_startTime);
    }
    function getCurrentTotalAPY(address mineCoin)public view returns (uint256) {
        if (totalDistribution == 0 || mineInfoMap[mineCoin].mineInterval == 0){
            return 0;
        }
        uint256 baseMine = mineInfoMap[mineCoin].mineAmount.mul(365 days)/mineInfoMap[mineCoin].mineInterval;
        return baseMine.mul(getweightDistribution(getPeriodIndex(currentTime())))/totalDistribution;
    }
    /**
     * @dev Calculate user's current APY.
     * @param account user's account.
     * @param mineCoin mine coin address
     */
    function getUserCurrentAPY(address account,address mineCoin)public view returns (uint256) {
        if (totalDistribution == 0 || mineInfoMap[mineCoin].mineInterval == 0){
            return 0;
        }
        uint256 baseMine = mineInfoMap[mineCoin].mineAmount.mul(365 days).mul(
                userInfoMap[account].distribution)/totalDistribution/mineInfoMap[mineCoin].mineInterval;
        return baseMine.mul(getPeriodWeight(getPeriodIndex(currentTime()),userInfoMap[account].maxPeriodID))/1000;
    }
    /**
     * @dev Calculate average locked time.
     */
    function getAverageLockedTime()public view returns (uint256) {
        if (totalDistribution == 0){
            return 0;
        }
        uint256 i = _maxPeriod-1;
        uint256 nowIndex = getPeriodIndex(currentTime());
        uint256 allLockedPeriod;
        uint256 periodDistri = weightDistributionMap[nowIndex+i]/4;
        allLockedPeriod = periodDistri.mul(getPeriodFinishTime(nowIndex+i).sub(currentTime()));
        i--;
        for (;;i--){
            //p[i] = (p[i+1]*3+w[i]+w[i+2]-w[i+1]*2)4
            periodDistri = periodDistri.mul(3).add(weightDistributionMap[nowIndex+i]).add(weightDistributionMap[nowIndex+i+2]);
            uint256 subWeight = weightDistributionMap[nowIndex+i+1].mul(2);
            if (periodDistri>subWeight){
                periodDistri = (periodDistri-subWeight)/4;
            }else{
                periodDistri = 0;
            }
            allLockedPeriod = allLockedPeriod.add(periodDistri.mul(getPeriodFinishTime(nowIndex+i).sub(currentTime())));
            if (i == 0){
                break;
            }
        }
        return allLockedPeriod.div(totalDistribution);
    }

    /**
     * @dev the auxiliary function for _mineSettlementAll.
     * @param mineCoin mine coin address
     */    
    function _mineSettlement(address mineCoin)internal{
        uint256 latestTime = mineInfoMap[mineCoin].latestSettleTime;
        uint256 curIndex = getPeriodIndex(latestTime);
        if (curIndex == 0){
            latestTime = _startTime;
        }
        uint256 nowIndex = getPeriodIndex(currentTime());
        if (nowIndex == 0){
            return;
        }
        for (uint256 i=0;i<_maxLoop;i++){
            // If the fixed distribution is zero, we only need calculate 
            uint256 finishTime = getPeriodFinishTime(curIndex);
            if (finishTime < currentTime()){
                _mineSettlementPeriod(mineCoin,curIndex,finishTime.sub(latestTime));
                latestTime = finishTime;
            }else{
                _mineSettlementPeriod(mineCoin,curIndex,currentTime().sub(latestTime));
                latestTime = currentTime();
                break;
            }
            curIndex++;
            if (curIndex > nowIndex){
                break;
            }
        }
        mineInfoMap[mineCoin].periodMinedNetWorth[nowIndex] = mineInfoMap[mineCoin].minedNetWorth;
        uint256 _mineInterval = mineInfoMap[mineCoin].mineInterval;
        if (_mineInterval>0){
            mineInfoMap[mineCoin].latestSettleTime = currentTime()/_mineInterval*_mineInterval;
        }else{
            mineInfoMap[mineCoin].latestSettleTime = currentTime();
        }
    }
    /**
     * @dev the auxiliary function for _mineSettlement. Calculate and record a period mine production. 
     * @param mineCoin mine coin address
     * @param periodID period time
     * @param mineTime covered time.
     */  
    function _mineSettlementPeriod(address mineCoin,uint256 periodID,uint256 mineTime)internal{
        uint256 totalDistri = totalDistribution;
        if (totalDistri > 0){
            uint256 latestMined = _getPeriodMined(mineCoin,mineTime);
            if (latestMined>0){
                mineInfoMap[mineCoin].minedNetWorth = mineInfoMap[mineCoin].minedNetWorth.add(latestMined.mul(calDecimals)/totalDistri);
                mineInfoMap[mineCoin].totalMinedCoin = mineInfoMap[mineCoin].totalMinedCoin.add(latestMined.mul(
                    getweightDistribution(periodID))/totalDistri);
            }
        }
        mineInfoMap[mineCoin].periodMinedNetWorth[periodID] = mineInfoMap[mineCoin].minedNetWorth;
    }
    /**
     * @dev Calculate and record user's mine production. 
     * @param mineCoin mine coin address
     * @param account user's account
     */  
    function _settleUserMine(address mineCoin,address account) internal {
        uint256 nowIndex = getPeriodIndex(currentTime());
        if (nowIndex == 0){
            return;
        }
        if(userInfoMap[account].distribution>0){
            uint256 userPeriod = userInfoMap[account].settlePeriod[mineCoin];
            if(userPeriod == 0){
                userPeriod = 1;
            }
            if (userPeriod < mineInfoMap[mineCoin].startPeriod){
                userPeriod = mineInfoMap[mineCoin].startPeriod;
            }
            for (uint256 i = 0;i<_maxLoop;i++){
                _settlementPeriod(mineCoin,account,userPeriod);
                if (userPeriod >= nowIndex){
                    break;
                }
                userPeriod++;
            }
        }
        userInfoMap[account].minerOrigins[mineCoin] = _getTokenNetWorth(mineCoin,nowIndex);
        userInfoMap[account].settlePeriod[mineCoin] = nowIndex;
    }
    /**
     * @dev the auxiliary function for _settleUserMine. Calculate and record a period mine production. 
     * @param mineCoin mine coin address
     * @param account user's account
     * @param periodID period time
     */ 
    function _settlementPeriod(address mineCoin,address account,uint256 periodID) internal {
        uint256 tokenNetWorth = _getTokenNetWorth(mineCoin,periodID);
        if (totalDistribution > 0){
            userInfoMap[account].minerBalances[mineCoin] = userInfoMap[account].minerBalances[mineCoin].add(
                _settlement(mineCoin,account,periodID,tokenNetWorth));
        }
        userInfoMap[account].minerOrigins[mineCoin] = tokenNetWorth;
    }
    /**
     * @dev retrieve each period's networth. 
     * @param mineCoin mine coin address
     * @param periodID period time
     */ 
    function _getTokenNetWorth(address mineCoin,uint256 periodID)internal view returns(uint256){
        return mineInfoMap[mineCoin].periodMinedNetWorth[periodID];
    }

    /**
     * @dev the auxiliary function for getMinerBalance. Calculate mine amount during latest time phase.
     * @param mineCoin mine coin address
     * @param account user's account
     */ 
    function _getUserLatestMined(address mineCoin,address account)internal view returns(uint256){
        uint256 userDistri = userInfoMap[account].distribution;
        if (userDistri == 0){
            return 0;
        }
        uint256 userperiod = userInfoMap[account].settlePeriod[mineCoin];
        if (userperiod < mineInfoMap[mineCoin].startPeriod){
            userperiod = mineInfoMap[mineCoin].startPeriod;
        }
        uint256 origin = userInfoMap[account].minerOrigins[mineCoin];
        uint256 latestMined = 0;
        uint256 nowIndex = getPeriodIndex(currentTime());
        uint256 userMaxPeriod = userInfoMap[account].maxPeriodID;
        uint256 netWorth = _getTokenNetWorth(mineCoin,userperiod);

        for (uint256 i=0;i<_maxLoop;i++){
            if(userperiod > nowIndex){
                break;
            }
            if (totalDistribution == 0){
                break;
            }
            netWorth = getPeriodNetWorth(mineCoin,userperiod,netWorth);
            latestMined = latestMined.add(userDistri.mul(netWorth.sub(origin)).mul(getPeriodWeight(userperiod,userMaxPeriod))/1000/calDecimals);
            origin = netWorth;
            userperiod++;
        }
        return latestMined;
    }
    /**
     * @dev the auxiliary function for _getUserLatestMined. Calculate token net worth in each period.
     * @param mineCoin mine coin address
     * @param periodID Period ID
     * @param preNetWorth The previous period's net worth.
     */ 
    function getPeriodNetWorth(address mineCoin,uint256 periodID,uint256 preNetWorth) internal view returns(uint256) {
        uint256 latestTime = mineInfoMap[mineCoin].latestSettleTime;
        uint256 curPeriod = getPeriodIndex(latestTime);
        if(periodID < curPeriod){
            return mineInfoMap[mineCoin].periodMinedNetWorth[periodID];
        }else{
            if (preNetWorth<mineInfoMap[mineCoin].periodMinedNetWorth[periodID]){
                preNetWorth = mineInfoMap[mineCoin].periodMinedNetWorth[periodID];
            }
            uint256 finishTime = getPeriodFinishTime(periodID);
            if (finishTime >= currentTime()){
                finishTime = currentTime();
            }
            if(periodID > curPeriod){
                latestTime = getPeriodFinishTime(periodID-1);
            }
            if (totalDistribution == 0){
                return preNetWorth;
            }
            uint256 periodMind = _getPeriodMined(mineCoin,finishTime.sub(latestTime));
            return preNetWorth.add(periodMind.mul(calDecimals)/totalDistribution);
        }
    }
    /**
     * @dev the auxiliary function for getTotalMined. Calculate mine amount during latest time phase .
     * @param mineCoin mine coin address
     */ 
    function _getLatestMined(address mineCoin)internal view returns(uint256){
        uint256 latestTime = mineInfoMap[mineCoin].latestSettleTime;
        uint256 curIndex = getPeriodIndex(latestTime);
        uint256 latestMined = 0;
        for (uint256 i=0;i<_maxLoop;i++){
            if (totalDistribution == 0){
                break;
            }
            uint256 finishTime = getPeriodFinishTime(curIndex);
            if (finishTime < currentTime()){
                latestMined = latestMined.add(_getPeriodWeightMined(mineCoin,curIndex,finishTime.sub(latestTime)));
            }else{
                latestMined = latestMined.add(_getPeriodWeightMined(mineCoin,curIndex,currentTime().sub(latestTime)));
                break;
            }
            curIndex++;
            latestTime = finishTime;
        }
        return latestMined;
    }
    /**
     * @dev Calculate mine amount
     * @param mineCoin mine coin address
     * @param mintTime mine duration.
     */ 
    function _getPeriodMined(address mineCoin,uint256 mintTime)internal view returns(uint256){
        uint256 _mineInterval = mineInfoMap[mineCoin].mineInterval;
        if (totalDistribution > 0 && _mineInterval>0){
            uint256 _mineAmount = mineInfoMap[mineCoin].mineAmount;
            mintTime = mintTime/_mineInterval;
            uint256 latestMined = _mineAmount.mul(mintTime);
            return latestMined;
        }
        return 0;
    }
    /**
     * @dev Calculate mine amount multiply weight ratio in each period.
     * @param mineCoin mine coin address
     * @param mineCoin period ID.
     * @param mintTime mine duration.
     */ 
    function _getPeriodWeightMined(address mineCoin,uint256 periodID,uint256 mintTime)internal view returns(uint256){
        if (totalDistribution > 0){
            return _getPeriodMined(mineCoin,mintTime).mul(getweightDistribution(periodID))/totalDistribution;
        }
        return 0;
    }
    /**
     * @dev Auxiliary function, calculate user's latest mine amount.
     * @param mineCoin the mine coin address
     * @param account user's account
     * @param tokenNetWorth the latest token net worth
     */
    function _settlement(address mineCoin,address account,uint256 periodID,uint256 tokenNetWorth)internal view returns (uint256) {
        uint256 origin = userInfoMap[account].minerOrigins[mineCoin];
        uint256 userMaxPeriod = userInfoMap[account].maxPeriodID;
        require(tokenNetWorth>=origin,"error: tokenNetWorth logic error!");
        return userInfoMap[account].distribution.mul(tokenNetWorth-origin).mul(getPeriodWeight(periodID,userMaxPeriod))/1000/calDecimals;
    }
    /**
     * @dev Stake FPT-A coin and get distribution for mining.
     * @param amount FPT-A amount that transfer into mine pool.
     */
    function stakeFPTA(uint256 amount)public minePoolStarted nonReentrant notHalted{
        amount = getPayableAmount(_FPTA,amount);
        require(amount > 0, 'stake amount is zero');
        removeDistribution(msg.sender);
        userInfoMap[msg.sender]._FPTABalance = userInfoMap[msg.sender]._FPTABalance.add(amount);
        addDistribution(msg.sender);
        emit StakeFPTA(msg.sender,amount);
    }
    /**
     * @dev Air drop to user some FPT-B coin and lock one period and get distribution for mining.
     * @param user air drop's recieptor.
     * @param ftp_b_amount FPT-B amount that transfer into mine pool.
     */
    function lockAirDrop(address user,uint256 ftp_b_amount) minePoolStarted notHalted external{
        if (msg.sender == getOperator(1)){
            lockAirDrop_base(user,ftp_b_amount);
        }else if (msg.sender == getOperator(2)){
            lockAirDrop_stake(user,ftp_b_amount);
        }else{
            require(false ,"Operator: caller is not the eligible Operator");
        }
    }

    function lockAirDrop_base(address user,uint256 ftp_b_amount) internal{
        uint256 curPeriod = getPeriodIndex(currentTime());
        uint256 maxId = userInfoMap[user].maxPeriodID;
        uint256 lockedPeriod = curPeriod > maxId ? curPeriod : maxId;
        ftp_b_amount = getPayableAmount(_FPTB,ftp_b_amount);
        require(ftp_b_amount > 0, 'stake amount is zero');
        removeDistribution(user);
        userInfoMap[user]._FPTBBalance = userInfoMap[user]._FPTBBalance.add(ftp_b_amount);
        userInfoMap[user].maxPeriodID = lockedPeriod;
        userInfoMap[user].lockedExpired = getPeriodFinishTime(lockedPeriod);
        addDistribution(user);
        emit LockAirDrop(msg.sender,user,ftp_b_amount);
    } 
    function lockAirDrop_stake(address user,uint256 lockedPeriod) internal validPeriod(lockedPeriod) {
        uint256 curPeriod = getPeriodIndex(currentTime());
        uint256 userMaxPeriod = curPeriod+lockedPeriod-1;

        require(userMaxPeriod>=userInfoMap[user].maxPeriodID, "lockedPeriod cannot be smaller than current locked period");
        if(userInfoMap[user].maxPeriodID<curPeriod && lockedPeriod == 1){
            require(getPeriodFinishTime(userMaxPeriod)>currentTime() + _flexibleExpired, 'locked time must greater than 15 days');
        }
        uint256 ftp_a_amount = IERC20(_FPTA).balanceOf(msg.sender);
        ftp_a_amount = getPayableAmount(_FPTA,ftp_a_amount);
        uint256 ftp_b_amount = IERC20(_FPTB).balanceOf(msg.sender);
        ftp_b_amount = getPayableAmount(_FPTB,ftp_b_amount);
        require(ftp_a_amount > 0 || ftp_b_amount > 0, 'stake amount is zero');
        removeDistribution(user);
        userInfoMap[user]._FPTABalance = userInfoMap[user]._FPTABalance.add(ftp_a_amount);
        userInfoMap[user]._FPTBBalance = userInfoMap[user]._FPTBBalance.add(ftp_b_amount);
        if (userInfoMap[user]._FPTBBalance > 0)
        {
            if (lockedPeriod == 0){
                userInfoMap[user].maxPeriodID = 0;
                if (ftp_b_amount>0){
                    userInfoMap[user].lockedExpired = currentTime().add(_flexibleExpired);
                }
            }else{
                userInfoMap[user].maxPeriodID = userMaxPeriod;
                userInfoMap[user].lockedExpired = getPeriodFinishTime(userMaxPeriod);
            }
        }
        addDistribution(user);
        emit StakeFPTA(user,ftp_a_amount);
        emit StakeFPTB(user,ftp_b_amount,lockedPeriod);
    } 
    /**
     * @dev Stake FPT-B coin and lock locedPreiod and get distribution for mining.
     * @param amount FPT-B amount that transfer into mine pool.
     * @param lockedPeriod locked preiod number.
     */
    function stakeFPTB(uint256 amount,uint256 lockedPeriod)public validPeriod(lockedPeriod) minePoolStarted nonReentrant notHalted{
        uint256 curPeriod = getPeriodIndex(currentTime());
        uint256 userMaxPeriod = curPeriod+lockedPeriod-1;
        require(userMaxPeriod>=userInfoMap[msg.sender].maxPeriodID, "lockedPeriod cannot be smaller than current locked period");
        if(userInfoMap[msg.sender].maxPeriodID<curPeriod && lockedPeriod == 1){
            require(getPeriodFinishTime(userMaxPeriod)>currentTime() + _flexibleExpired, 'locked time must greater than 15 days');
        }
        amount = getPayableAmount(_FPTB,amount);
        require(amount > 0, 'stake amount is zero');
        removeDistribution(msg.sender);
        userInfoMap[msg.sender]._FPTBBalance = userInfoMap[msg.sender]._FPTBBalance.add(amount);
        if (lockedPeriod == 0){
            userInfoMap[msg.sender].maxPeriodID = 0;
            userInfoMap[msg.sender].lockedExpired = currentTime().add(_flexibleExpired);
        }else{
            userInfoMap[msg.sender].maxPeriodID = userMaxPeriod;
            userInfoMap[msg.sender].lockedExpired = getPeriodFinishTime(userMaxPeriod);
        }
        addDistribution(msg.sender);
        emit StakeFPTB(msg.sender,amount,lockedPeriod);
    }
    /**
     * @dev withdraw FPT-A coin.
     * @param amount FPT-A amount that withdraw from mine pool.
     */
    function unstakeFPTA(uint256 amount)public nonReentrant notHalted{
        require(amount > 0, 'unstake amount is zero');
        require(userInfoMap[msg.sender]._FPTABalance >= amount,
            'unstake amount is greater than total user stakes');
        removeDistribution(msg.sender);
        userInfoMap[msg.sender]._FPTABalance = userInfoMap[msg.sender]._FPTABalance - amount;
        addDistribution(msg.sender);
        _redeem(msg.sender,_FPTA,amount);
        emit UnstakeFPTA(msg.sender,amount);
    }
    /**
     * @dev withdraw FPT-B coin.
     * @param amount FPT-B amount that withdraw from mine pool.
     */
    function unstakeFPTB(uint256 amount)public nonReentrant notHalted minePoolStarted periodExpired(msg.sender){
        require(amount > 0, 'unstake amount is zero');
        require(userInfoMap[msg.sender]._FPTBBalance >= amount,
            'unstake amount is greater than total user stakes');
        removeDistribution(msg.sender);
        userInfoMap[msg.sender]._FPTBBalance = userInfoMap[msg.sender]._FPTBBalance - amount;
        addDistribution(msg.sender);
        _redeem(msg.sender,_FPTB,amount);
        emit UnstakeFPTB(msg.sender,amount);
    }
    /**
     * @dev Add FPT-B locked period.
     * @param lockedPeriod FPT-B locked preiod number.
     */
    function changeFPTBLockedPeriod(uint256 lockedPeriod)public validPeriod(lockedPeriod) minePoolStarted notHalted{
        require(userInfoMap[msg.sender]._FPTBBalance > 0, "stake FPTB balance is zero");
        uint256 curPeriod = getPeriodIndex(currentTime());
        require(curPeriod+lockedPeriod-1>=userInfoMap[msg.sender].maxPeriodID, "lockedPeriod cannot be smaller than current locked period");
        removeDistribution(msg.sender); 
        if (lockedPeriod == 0){
            userInfoMap[msg.sender].maxPeriodID = 0;
            userInfoMap[msg.sender].lockedExpired = currentTime().add(_flexibleExpired);
        }else{
            userInfoMap[msg.sender].maxPeriodID = curPeriod+lockedPeriod-1;
            userInfoMap[msg.sender].lockedExpired = getPeriodFinishTime(curPeriod+lockedPeriod-1);
        }
        addDistribution(msg.sender);
        emit ChangeLockedPeriod(msg.sender,lockedPeriod);
    }
    /**
     * @dev Auxiliary function. getting user's payment
     * @param settlement user's payment coin.
     * @param settlementAmount user's payment amount.
     */
    function getPayableAmount(address settlement,uint256 settlementAmount) internal returns (uint256) {
        if (settlement == address(0)){
            settlementAmount = msg.value;
        }else if (settlementAmount > 0){
            IERC20 oToken = IERC20(settlement);
            uint256 preBalance = oToken.balanceOf(address(this));
            SafeERC20.safeTransferFrom(oToken,msg.sender, address(this), settlementAmount);
            //oToken.transferFrom(msg.sender, address(this), settlementAmount);
            uint256 afterBalance = oToken.balanceOf(address(this));
            require(afterBalance-preBalance==settlementAmount,"settlement token transfer error!");
        }
        return settlementAmount;
    }
    /**
     * @dev Auxiliary function. Clear user's distribution amount.
     * @param account user's account.
     */
    function removeDistribution(address account) internal {
        uint256 addrLen = whiteList.length;
        for(uint256 i=0;i<addrLen;i++){
            _mineSettlement(whiteList[i]);
            _settleUserMine(whiteList[i],account);
        }
        uint256 distri = calculateDistribution(account);
        totalDistribution = totalDistribution.sub(distri);
        uint256 nowId = getPeriodIndex(currentTime());
        uint256 endId = userInfoMap[account].maxPeriodID;
        for(;nowId<=endId;nowId++){
            weightDistributionMap[nowId] = weightDistributionMap[nowId].sub(distri.mul(getPeriodWeight(nowId,endId)-1000)/1000);
        }
        userInfoMap[account].distribution =  0;
        removePremiumDistribution(account);
    }
    /**
     * @dev Auxiliary function. Add user's distribution amount.
     * @param account user's account.
     */
    function addDistribution(address account) internal {
        uint256 distri = calculateDistribution(account);
        uint256 nowId = getPeriodIndex(currentTime());
        uint256 endId = userInfoMap[account].maxPeriodID;
        for(;nowId<=endId;nowId++){
            weightDistributionMap[nowId] = weightDistributionMap[nowId].add(distri.mul(getPeriodWeight(nowId,endId)-1000)/1000);
        }
        userInfoMap[account].distribution =  distri;
        totalDistribution = totalDistribution.add(distri);
        addPremiumDistribution(account);
    }
    /**
     * @dev Auxiliary function. calculate user's distribution.
     * @param account user's account.
     */
    function calculateDistribution(address account) internal view returns (uint256){
        uint256 fptAAmount = userInfoMap[account]._FPTABalance;
        uint256 fptBAmount = userInfoMap[account]._FPTBBalance;
        uint256 repeat = (fptAAmount>fptBAmount*10) ? fptBAmount*10 : fptAAmount;
        return _FPTARatio.mul(fptAAmount).add(_FPTBRatio.mul(fptBAmount)).add(
            _RepeatRatio.mul(repeat));
    }
    /**
     * @dev Auxiliary function. get weight distribution in each period.
     * @param periodID period ID.
     */
    function getweightDistribution(uint256 periodID)internal view returns (uint256) {
        return weightDistributionMap[periodID].add(totalDistribution);
    }
    /**
     * @dev Auxiliary function. get mine weight ratio from current period to one's maximium period.
     * @param currentID current period ID.
     * @param maxPeriod user's maximium period ID.
     */
    function getPeriodWeight(uint256 currentID,uint256 maxPeriod) public view returns (uint256) {
        if (maxPeriod == 0 || currentID > maxPeriod){
            return 1000;
        }

        return periodWeights[maxPeriod.sub(currentID)];
    }

    /**
     * @dev retrieve total distributed options premium.
     */
    function getTotalPremium(address premiumCoin)public view returns(uint256){
        return premiumMap[premiumCoin].totalPremium;
    }

    /**
     * @dev user redeem his options premium rewards.
     */
    function redeemPremium()public nonReentrant notHalted {
        for (uint256 i=0;i<premiumCoinList.length;i++){
            address premiumCoin = premiumCoinList[i];
            settlePremium(msg.sender,premiumCoin);
            uint256 amount = premiumMap[premiumCoin].premiumBalance[msg.sender];
            if (amount > 0){
                premiumMap[premiumCoin].premiumBalance[msg.sender] = 0;
                _redeem(msg.sender,premiumCoin,amount);
                emit RedeemPremium(msg.sender,premiumCoin,amount);
            }
        }
    }
    /**
     * @dev user redeem his options premium rewards.
     * @param amount redeem amount.
     */
    function redeemPremiumCoin(address premiumCoin,uint256 amount)public nonReentrant notHalted {
        require(amount > 0,"redeem amount must be greater than zero");
        settlePremium(msg.sender,premiumCoin);
        premiumMap[premiumCoin].premiumBalance[msg.sender] = premiumMap[premiumCoin].premiumBalance[msg.sender].sub(amount);
        _redeem(msg.sender,premiumCoin,amount);
        emit RedeemPremium(msg.sender,premiumCoin,amount);
    }

    /**
     * @dev get user's premium balance.
     * @param account user's account
     */ 
    function getUserLatestPremium(address account,address premiumCoin)public view returns(uint256){
        return premiumMap[premiumCoin].premiumBalance[account].add(_getUserPremium(account,premiumCoin));
    }
    /**
     * @dev the auxiliary function for getUserLatestPremium. Calculate latest time phase premium.
     */ 
    function _getUserPremium(address account,address premiumCoin)internal view returns(uint256){
        uint256 FPTBBalance = userInfoMap[account]._FPTBBalance;
        if (FPTBBalance > 0){
            uint256 lastIndex = premiumMap[premiumCoin].lastPremiumIndex[account];
            uint256 nowIndex = getPeriodIndex(currentTime());
            uint256 endIndex = lastIndex+_maxLoop < premiumMap[premiumCoin].distributedPeriod.length ? lastIndex+_maxLoop : premiumMap[premiumCoin].distributedPeriod.length;
            uint256 LatestPremium = 0;
            for (; lastIndex< endIndex;lastIndex++){
                uint256 periodID = premiumMap[premiumCoin].distributedPeriod[lastIndex];
                if (periodID == nowIndex || premiumDistributionMap[periodID].totalPremiumDistribution == 0 ||
                    premiumDistributionMap[periodID].userPremiumDistribution[account] == 0){
                    continue;
                }
                LatestPremium = LatestPremium.add(premiumMap[premiumCoin].periodPremium[periodID].mul(premiumDistributionMap[periodID].userPremiumDistribution[account]).div(
                    premiumDistributionMap[periodID].totalPremiumDistribution));
            }        
            return LatestPremium;
        }
        return 0;
    }
    /**
     * @dev Distribute premium from foundation.
     * @param premiumCoin premium token address
     * @param periodID period ID
     * @param amount premium amount.
     */ 
    function distributePremium(address premiumCoin, uint256 periodID,uint256 amount)public onlyOperator(0) {
        amount = getPayableAmount(premiumCoin,amount);
        require(amount > 0, 'Distribution amount is zero');
        require(premiumMap[premiumCoin].periodPremium[periodID] == 0 , "This period is already distributed!");
        uint256 nowIndex = getPeriodIndex(currentTime());
        require(nowIndex > periodID, 'This period is not finished');
        whiteListAddress.addWhiteListAddress(premiumCoinList,premiumCoin);
        premiumMap[premiumCoin].periodPremium[periodID] = amount;
        premiumMap[premiumCoin].totalPremium = premiumMap[premiumCoin].totalPremium.add(amount);
        premiumMap[premiumCoin].distributedPeriod.push(uint64(periodID));
        emit DistributePremium(msg.sender,premiumCoin,periodID,amount);
    }
    /**
     * @dev Auxiliary function. Clear user's premium distribution amount.
     * @param account user's account.
     */ 
    function removePremiumDistribution(address account) internal {
        for (uint256 i=0;i<premiumCoinList.length;i++){
            settlePremium(account,premiumCoinList[i]);
        }
        uint256 beginTime = currentTime(); 
        uint256 nowId = getPeriodIndex(beginTime);
        uint256 endId = userInfoMap[account].maxPeriodID;
        uint256 FPTBBalance = userInfoMap[account]._FPTBBalance;
        if (FPTBBalance> 0 && nowId<endId){
            for(;nowId<endId;nowId++){
                uint256 finishTime = getPeriodFinishTime(nowId);
                uint256 periodDistribution = finishTime.sub(beginTime).mul(FPTBBalance);
                premiumDistributionMap[nowId].totalPremiumDistribution = premiumDistributionMap[nowId].totalPremiumDistribution.sub(periodDistribution);
                premiumDistributionMap[nowId].userPremiumDistribution[account] = premiumDistributionMap[nowId].userPremiumDistribution[account].sub(periodDistribution);
                beginTime = finishTime;
            }
        }
    }
    /**
     * @dev Auxiliary function. Calculate and record user's premium.
     * @param account user's account.
     */ 
    function settlePremium(address account,address premiumCoin)internal{
        premiumMap[premiumCoin].premiumBalance[account] = premiumMap[premiumCoin].premiumBalance[account].add(getUserLatestPremium(account,premiumCoin));
        premiumMap[premiumCoin].lastPremiumIndex[account] = premiumMap[premiumCoin].distributedPeriod.length;
    }
    /**
     * @dev Auxiliary function. Add user's premium distribution amount.
     * @param account user's account.
     */ 
    function addPremiumDistribution(address account) internal {
        uint256 beginTime = currentTime(); 
        uint256 nowId = getPeriodIndex(beginTime);
        uint256 endId = userInfoMap[account].maxPeriodID;
        uint256 FPTBBalance = userInfoMap[account]._FPTBBalance;
        for(;nowId<endId;nowId++){
            uint256 finishTime = getPeriodFinishTime(nowId);
            uint256 periodDistribution = finishTime.sub(beginTime).mul(FPTBBalance);
            premiumDistributionMap[nowId].totalPremiumDistribution = premiumDistributionMap[nowId].totalPremiumDistribution.add(periodDistribution);
            premiumDistributionMap[nowId].userPremiumDistribution[account] = premiumDistributionMap[nowId].userPremiumDistribution[account].add(periodDistribution);
            beginTime = finishTime;
        }

    }
    /**
     * @dev Throws if user's locked expired timestamp is less than now.
     */
    modifier periodExpired(address account){
        require(userInfoMap[account].lockedExpired < currentTime(),'locked period is not expired');

        _;
    }
    /**
     * @dev Throws if input period number is greater than _maxPeriod.
     */
    modifier validPeriod(uint256 period){
        require(period >= 0 && period <= _maxPeriod, 'locked period must be in valid range');
        _;
    }
    /**
     * @dev Throws if minePool is not start.
     */
    modifier minePoolStarted(){
        require(currentTime()>=_startTime, 'mine pool is not start');
        _;
    }
    /**
     * @dev get now timestamp.
     */
    function currentTime() internal view returns (uint256){
        return now;
    }

    function  collectFee(address mineCoin,uint256 amount) internal returns (uint256){
        require(msg.value>=_htFeeAmount,"need input ht coin value 0.01");

        //charged ht fee
        _feeReciever.transfer(_htFeeAmount);

        if (mineCoin != address(0)){
            //charge fnx token fee
            uint256 fee = amount.mul(_fnxFeeRatio).div(1000);
            IERC20 token = IERC20(mineCoin);
            uint256 preBalance = token.balanceOf(address(this));
            SafeERC20.safeTransfer(token,_feeReciever,fee);
            uint256 afterBalance = token.balanceOf(address(this));
            require(preBalance - afterBalance == fee,"settlement token transfer error!");

            return amount.sub(fee);
        }

        return amount;
    }

    function setFeePara(uint256 fnxFeeRatio,uint256 htFeeAmount,address payable feeReciever) onlyOwner public {
        if(fnxFeeRatio>0) {
            _fnxFeeRatio = fnxFeeRatio;
        }
        if(htFeeAmount >0 ) {
            _htFeeAmount = htFeeAmount;
        }
        if(feeReciever != address(0)){
            _feeReciever = feeReciever;
        }
    }
}