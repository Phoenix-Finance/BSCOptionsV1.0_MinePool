pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * FinNexus
 * Copyright (C) 2020 FinNexus Options Protocol
 */
import "../fixedMinePool/fixedMinePoolProxy.sol";
/**
 * @title FPTCoin mine pool, which manager contract is FPTCoin.
 * @dev A smart-contract which distribute some mine coins by FPTCoin balance.
 *
 */
contract testMinePoolProxy is fixedMinePoolProxy {
    constructor (address implementation_,address FPTA,address FPTB,uint256 startTime)public
         fixedMinePoolProxy(implementation_,FPTA,FPTB,startTime){
    }
    function setTime(uint256 /*_time*/) public{
        delegateAndReturn();
    }
    function getTotalDistribution() public view returns (uint256){
        delegateToViewAndReturn();
    }
    function getPeriodWeightDistribution(uint256 /*periodId*/) public view returns (uint256){
        delegateToViewAndReturn();
    }
    function getUserDistribution(address /*account*/) public view returns (uint256){
        delegateToViewAndReturn();
    }
    function getDistributionCal(address /*account*/) public view returns (uint256){
        delegateToViewAndReturn();
    }
    function getTokenNetWorth(address /*mineCoin*/,uint256 /*periodID*/)public view returns(uint256){
        delegateToViewAndReturn();
    }
    function getUserSettlePeriod(address /*account*/,address /*mineCoin*/)public view returns(uint256){
        delegateToViewAndReturn();
    }

}