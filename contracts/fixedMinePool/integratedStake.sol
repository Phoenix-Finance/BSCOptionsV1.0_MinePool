pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * FinNexus
 * Copyright (C) 2020 FinNexus Options Protocol
 */
import "../ERC20/safeErc20.sol";
import "../modules/Ownable.sol";
 interface IOptionMgrPoxy {
    function addCollateral(address collateral,uint256 amount) external payable;
}

interface IMinePool {
    function lockAirDrop(address user,uint256 ftp_b_amount) external;
}

contract integratedStake is Ownable{
    using SafeERC20 for IERC20;
    address public _FPTA;
    address public _FPTB;
    address public _FPTAColPool;//the option manager address
    address public _FPTBColPool;//the option manager address
    address public _minePool;    //the fixed minePool address
    mapping (address=>bool) approveMapA;
    mapping (address=>bool) approveMapB;
    uint256  constant internal MAX_UINT = (2**256 - 1); 
    /**
     * @dev constructor.
     */
    constructor(address FPTA,address FPTB,address FPTAColPool,address FPTBColPool,address minePool)public{
        setAddress(FPTA,FPTB,FPTAColPool,FPTBColPool,minePool);
    }
    function setAddress(address FPTA,address FPTB,address FPTAColPool,address FPTBColPool,address minePool) onlyOwner public{
        _FPTA = FPTA;
        _FPTB = FPTB;
        _FPTAColPool = FPTAColPool;
        _FPTBColPool = FPTBColPool;
        _minePool = minePool;
        if (IERC20(_FPTA).allowance(msg.sender, _minePool) == 0){
            IERC20(_FPTA).safeApprove(_minePool,MAX_UINT);
        }
        if (IERC20(_FPTB).allowance(msg.sender, _minePool) == 0){
            IERC20(_FPTB).safeApprove(_minePool,MAX_UINT);
        }
    }
    function stake(address[] memory fpta_tokens,uint256[] memory fpta_amounts,
            address[] memory fptb_tokens,uint256[] memory fptb_amounts,uint256 lockedPeriod) public payable{
        require(fpta_tokens.length==fpta_amounts.length && fptb_tokens.length==fptb_amounts.length,"the input array length is not equal");
       // uint256 i = 0;
        addCollateralSub(fpta_tokens,fpta_amounts,_FPTAColPool,_FPTA);
        addCollateralSub(fptb_tokens,fptb_amounts,_FPTBColPool,_FPTB);
        IMinePool(_minePool).lockAirDrop(msg.sender,lockedPeriod);
    }
    function addCollateralSub(address[] memory fpt_tokens,uint256[] memory fpt_amounts,
        address FPTColPool,address FPT)internal {
        uint256 i = 0;
        uint256 coinAmount = 0;
        for(i = 0;i<fpt_tokens.length;i++) {
            uint256 amount = getPayableAmount(fpt_tokens[i],fpt_amounts[i]);
            if (fpt_tokens[i]== address(0)){
                coinAmount = amount;
            }
            else{
                coinAmount = 0;
                if ((!approveMapA[fpt_tokens[i]])){
                    IERC20(fpt_tokens[i]).safeApprove(FPTColPool,MAX_UINT);
                    approveMapA[fpt_tokens[i]] = true;
                }
            }
            IOptionMgrPoxy(FPTColPool).addCollateral.value(coinAmount)(fpt_tokens[i],amount);
            IERC20(FPT).safeTransfer(msg.sender,0);
        }
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
            oToken.safeTransferFrom(msg.sender, address(this), settlementAmount);
            //oToken.transferFrom(msg.sender, address(this), settlementAmount);
            uint256 afterBalance = oToken.balanceOf(address(this));
            require(afterBalance-preBalance==settlementAmount,"settlement token transfer error!");
        }
        return settlementAmount;
    }
}
