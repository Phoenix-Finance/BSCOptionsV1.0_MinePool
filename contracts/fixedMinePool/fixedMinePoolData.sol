pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * FinNexus
 * Copyright (C) 2020 FinNexus Options Protocol
 */
import "../modules/Halt.sol";
import "../modules/Operator.sol";
import "../modules/AddressWhiteList.sol";
import "../modules/ReentrancyGuard.sol";
import "../modules/initializable.sol";
/**
 * @title new Finnexus Options Pool token mine pool.
 * @dev A smart-contract which distribute some mine coins when you stake some FPT-A and FPT-B coins.
 *      Users who both stake some FPT-A and FPT-B coins will get more bonus in mine pool.
 *      Users who Lock FPT-B coins will get several times than normal miners.
 */
contract fixedMinePoolData is initializable,Operator,Halt,AddressWhiteList,ReentrancyGuard {
    //Special decimals for calculation
    uint256 constant calDecimals = 1e18;

    //The timestamp when the minepool begin.
    uint256 internal _startTime;
    //Single locked period duration.
    uint256 internal constant _period = 30 days;//90 days;
    //The lock duration when user stake flexible FPT-B in this pool.
    uint256 internal _flexibleExpired = 1 weeks;

    //The max locked peroid when user stake locked FPT-B coin.
    uint256 constant internal _maxPeriod = 6;//12;//6 months
    //The max loop when user does nothing to this pool for long long time .
    uint256 constant internal _maxLoop = 120;
    //the mine distribution's ratio to FPT-A coin 
    uint256 constant internal _FPTARatio = 1000;
    //the mine distribution's ratio to FPT-B coin 
    uint256 constant internal _FPTBRatio = 1000;
    //the mine distribution's ratio to FPT-A and FPT-B coin repetition
    uint256 constant internal _RepeatRatio = 3000;//20000;
    //the accumulated weight each period has.
    uint256 constant internal periodWeight = 500;//1000;
    uint256 constant internal baseWeight = 1000;//5000;

    uint256 public _fnxFeeRatio = 5;
    uint256 public _htFeeAmount = 1e16;
    address payable public _feeReciever;

    // FPT-A address
    address internal _FPTA;
    // FPT-B address
    address internal _FPTB;

    struct userInfo {
        //user's FPT-A staked balance
        uint256 _FPTABalance;
        //user's FPT-B staked balance
        uint256 _FPTBBalance;
        //Period ID start at 1. if a PeriodID equals zero, it means your FPT-B is flexible staked.
        //User's max locked period id;
        uint256 maxPeriodID;
        //User's max locked period timestamp. Flexible FPT-B is locked _flexibleExpired seconds;
        uint256 lockedExpired;
        //User's mine distribution.You can get base mine proportion by your distribution divided by total distribution.
        uint256 distribution;
        //User's settled mine coin balance.
        mapping(address=>uint256) minerBalances;
        //User's latest settled distribution net worth.
        mapping(address=>uint256) minerOrigins;
        //user's latest settlement period for each token.
        mapping(address=>uint256) settlePeriod;
    }
    struct tokenMineInfo {
        //mine distribution amount
        uint256 mineAmount;
        //mine distribution time interval
        uint256 mineInterval;
        //mine distribution first period
        uint256 startPeriod;
        //mine coin latest settlement time
        uint256 latestSettleTime;
        // total mine distribution till latest settlement time.
        uint256 totalMinedCoin;
        //latest distribution net worth;
        uint256 minedNetWorth;
        //period latest distribution net worth;
        mapping(uint256=>uint256) periodMinedNetWorth;
    }

    //User's staking and mining info.
    mapping(address=>userInfo) internal userInfoMap;
    //each mine coin's mining info.
    mapping(address=>tokenMineInfo) internal mineInfoMap;
    //total weight distribution which is used to calculate total mined amount.
    mapping(uint256=>uint256) internal weightDistributionMap;
    //total Distribution
    uint256 internal totalDistribution;

    struct premiumDistribution {
        //total premium distribution in each period
        uint256 totalPremiumDistribution;
        //User's premium distribution in each period
        mapping(address=>uint256) userPremiumDistribution;

    }
    // premium mining info in each period.
    mapping(uint256=>premiumDistribution) internal premiumDistributionMap;
    //user's latest redeemed period index in the distributedPeriod list.
    struct premiumInfo {
        mapping(address=>uint256) lastPremiumIndex;
        mapping(address=>uint256) premiumBalance;
        //period id list which is already distributed by owner.
        uint64[] distributedPeriod;
        //total permium distributed by owner.
        uint256 totalPremium;
        //total premium distributed by owner in each period.
        mapping(uint256=>uint256) periodPremium;
    }
    mapping(address=>premiumInfo) internal premiumMap;
    address[] internal premiumCoinList;

    /**
     * @dev Emitted when `account` stake `amount` FPT-A coin.
     */
    event StakeFPTA(address indexed account,uint256 amount);
    /**
     * @dev Emitted when `from` airdrop `recieptor` `amount` FPT-B coin.
     */
    event LockAirDrop(address indexed from,address indexed recieptor,uint256 amount);
    /**
     * @dev Emitted when `account` stake `amount` FPT-B coin and locked `lockedPeriod` periods.
     */
    event StakeFPTB(address indexed account,uint256 amount,uint256 lockedPeriod);
    /**
     * @dev Emitted when `account` unstake `amount` FPT-A coin.
     */
    event UnstakeFPTA(address indexed account,uint256 amount);
    /**
     * @dev Emitted when `account` unstake `amount` FPT-B coin.
     */
    event UnstakeFPTB(address indexed account,uint256 amount);
    /**
     * @dev Emitted when `account` change `lockedPeriod` locked periods for FPT-B coin.
     */
    event ChangeLockedPeriod(address indexed account,uint256 lockedPeriod);
    /**
     * @dev Emitted when owner `account` distribute `amount` premium in `periodID` period.
     */
    event DistributePremium(address indexed account,address indexed premiumCoin,uint256 indexed periodID,uint256 amount);
    /**
     * @dev Emitted when `account` redeem `amount` premium.
     */
    event RedeemPremium(address indexed account,address indexed premiumCoin,uint256 amount);

    /**
     * @dev Emitted when `account` redeem `value` mineCoins.
     */
    event RedeemMineCoin(address indexed account, address indexed mineCoin, uint256 value);

}
