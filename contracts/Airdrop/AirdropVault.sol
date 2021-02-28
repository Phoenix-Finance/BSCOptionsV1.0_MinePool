pragma solidity =0.5.16;
import "./AirdropVaultData.sol";
import "../modules/SafeMath.sol";
import "../ERC20/IERC20.sol";


interface IOptionMgrPoxy {
    function addCollateral(address collateral,uint256 amount) external payable;
}

interface IMinePool {
    function lockAirDrop(address user,uint256 ftp_b_amount) external;
}

interface ITargetToken {
     function balanceOf(address account) external view returns (uint256);
}


contract AirDropVault is AirDropVaultData {
    using SafeMath for uint256;
    
    modifier airdropinited() {
        require(optionColPool!=address(0),"collateral pool address should be set");
        require(minePool!=address(0),"mine pool address should be set");
        require(fnxToken!=address(0),"fnx token address should be set");
        require(ftpbToken!=address(0),"ftpb token address should be set");
        require(claimBeginTime>0,"airdrop claim begin time should be set");
        require(claimEndTime>0,"airdrop claim end time should be set");
        require(fnxPerFreeClaimUser>0,"the air drop number for each free claimer should be set");
        require(maxWhiteListFnxAirDrop>0,"the max fnx number for whitelist air drop should be set");
        require(maxFreeFnxAirDrop>0,"the max fnx number for free air drop should be set");
        _;
    }
    
    modifier suhsimineinited() {
        require(cfnxToken!=address(0),"cfnc token address should be set");
        require(sushiMineStartTime>0,"sushi mine start time should be set");
        require(sushimineInterval>0,"sushi mine interval should be set");
        _;
    }    

    function initialize() onlyOwner public {}
    
    function update() onlyOwner public{

    }
    
    
    /**
     * @dev init function,init air drop
     * @param _optionColPool  the option collateral contract address
     * @param _fnxToken  the fnx token address
     * @param _ftpbToken the ftpb token address
     * @param _claimBeginTime the start time for airdrop
     * @param _claimEndTime  the end time for airdrop
     * @param _fnxPerFreeClaimUser the fnx amo for each person in airdrop
     * @param _maxFreeFnxAirDrop the max fnx amount for free claimer from hegic,curve
     * @param _maxWhiteListFnxAirDrop the mx fnx number in whitelist ways
     */
    function initAirdrop( address _optionColPool,
                                address _minePool,
                                address _fnxToken,
                                address _ftpbToken,
                                uint256 _claimBeginTime,
                                uint256 _claimEndTime,
                                uint256 _fnxPerFreeClaimUser,
                                uint256 _maxFreeFnxAirDrop,
                                uint256 _maxWhiteListFnxAirDrop) public onlyOwner {
        if(_optionColPool!=address(0))                            
            optionColPool = _optionColPool;
        if(_minePool!=address(0))    
            minePool = _minePool;
        if(_fnxToken!=address(0))    
            fnxToken = _fnxToken;  
        if(_ftpbToken!=address(0))    
            ftpbToken = _ftpbToken;
        
        if(_claimBeginTime>0)    
            claimBeginTime = _claimBeginTime;
         
        if(_claimEndTime>0)    
            claimEndTime = _claimEndTime;
            
        if(_fnxPerFreeClaimUser>0)    
            fnxPerFreeClaimUser = _fnxPerFreeClaimUser;

        if(_maxFreeFnxAirDrop>0)
            maxFreeFnxAirDrop = _maxFreeFnxAirDrop;
            
        if(_maxWhiteListFnxAirDrop>0)    
            maxWhiteListFnxAirDrop = _maxWhiteListFnxAirDrop;

        //aprove optioncol fnx to unlimit
       // uint256  MAX_UINT = (2**256 - 1);
        //IERC20(fnxToken).approve(optionColPool,MAX_UINT);

        //IERC20(ftpbToken).approve(minePool,MAX_UINT);
    }
    
    /**
     * @dev init function,init sushi mine
     * @param _cfnxToken  the mined reward token
     * @param _sushiMineStartTime mine start time
     * @param _sushimineInterval the sushi mine time interval
     */
    function initSushiMine(address _cfnxToken,uint256 _sushiMineStartTime,uint256 _sushimineInterval) public onlyOwner{
        if(_cfnxToken!=address(0))
            cfnxToken = _cfnxToken;
        if(_sushiMineStartTime>0)    
            sushiMineStartTime = _sushiMineStartTime;
        if(_sushimineInterval>0)    
            sushimineInterval = _sushimineInterval;
    }
    

    /**
     * @dev getting back the left mine token
     * @param _reciever the reciever for getting back mine token
     */
    function getbackLeftFnx(address _reciever)  public onlyOwner {
        uint256 bal =  IERC20(fnxToken).balanceOf(address(this));
        if(bal>0)
            IERC20(fnxToken).transfer(_reciever,bal);
        
        bal = IERC20(ftpbToken).balanceOf(address(this));
        if(bal>0)
            IERC20(ftpbToken).transfer(_reciever,bal);

        bal = IERC20(cfnxToken).balanceOf(address(this));
        if(bal>0)
            IERC20(cfnxToken).transfer(_reciever,bal);            
            
    }  
    
    /**
     * reset token setting in case of setting is wrong
     */
    function resetTokenList()  public onlyOwner {
        uint256 i;
        for(i=0;i<tokenWhiteList.length;i++) {
            delete tkBalanceRequire[tokenWhiteList[i]];
        }
        
        tokenWhiteList.length = 0;
    }     

    /**
     * @dev Retrieve user's locked balance. 
     * @param _account user's account.
     */ 
    function balanceOfWhitListUser(address _account) private view returns (uint256) {
        
        if(totalWhiteListClaimed < maxWhiteListFnxAirDrop) {
            uint256 amount = userWhiteList[_account];
            uint256 total = totalWhiteListClaimed.add(amount);
            
            if (total>maxWhiteListFnxAirDrop){
                amount = maxWhiteListFnxAirDrop.sub(totalWhiteListClaimed);
            }
            
            return amount;
        }
        
        return 0;
       
    }

   /**
   * @dev setting function.set airdrop users address and balance in whitelist ways
   * @param _accounts   the user address.tested support 200 address in one tx
   * @param _fnxnumbers the user's airdrop fnx number
   */   
    function setWhiteList(address[] memory _accounts,uint256[] memory _fnxnumbers) public onlyOperator(1) {
        require(_accounts.length==_fnxnumbers.length,"the input array length is not equal");
        uint256 i = 0;
        for(;i<_accounts.length;i++) {
            if(userWhiteList[_accounts[i]]==0) {
               require(_fnxnumbers[i]>0,"fnx number must be over 0!");
               //just for tatics    
               totalWhiteListAirdrop = totalWhiteListAirdrop.add(_fnxnumbers[i]);
               userWhiteList[_accounts[i]] = _fnxnumbers[i];
               emit AddWhiteList(_accounts[i],_fnxnumbers[i]);
            }
        }
    }
    
    /**
    * @dev claim the airdrop for user in whitelist ways
    */
    function whitelistClaim() internal /*airdropinited*/ {
        // require(now >= claimBeginTime,"claim not begin");
        // require(now < claimEndTime,"claim finished");

        if(totalWhiteListClaimed < maxWhiteListFnxAirDrop) {
          
           if(userWhiteList[msg.sender]>0) {
               
                uint256 amount = userWhiteList[msg.sender];
                userWhiteList[msg.sender] = 0;
                uint256 total = totalWhiteListClaimed.add(amount);
                if (total>maxWhiteListFnxAirDrop){
                    amount = maxWhiteListFnxAirDrop.sub(totalWhiteListClaimed);
                }
                totalWhiteListClaimed = totalWhiteListClaimed.add(amount);

                IERC20(fnxToken).approve(optionColPool,amount);
                uint256 prefptb = IERC20(ftpbToken).balanceOf(address(this));
                IOptionMgrPoxy(optionColPool).addCollateral(fnxToken,amount);
                uint256 afterftpb = IERC20(ftpbToken).balanceOf(address(this));
                uint256 ftpbnum = afterftpb.sub(prefptb);
                IERC20(ftpbToken).approve(minePool,ftpbnum);
                IMinePool(minePool).lockAirDrop(msg.sender,ftpbnum);

                emit WhiteListClaim(msg.sender,amount,ftpbnum);


                //1000 fnx = 94 fpt
//                uint256 ftpbnum = 2 ether;
//                IERC20(ftpbToken).approve(minePool,ftpbnum);
//                IMinePool(minePool).lockAirDrop(msg.sender,ftpbnum);
//                emit UserFreeClaim(msg.sender,amount,ftpbnum);
            }
         }
    }
    
   /**
   * @dev setting function.set target token and required balance for airdrop token
   * @param _tokens   the tokens address.tested support 200 address in one tx
   * @param _minBalForFreeClaim  the required minimal balance for the claimer
   */    
    function setTokenList(address[] memory _tokens,uint256[] memory _minBalForFreeClaim) public onlyOwner {
        uint256 i = 0;
        require(_tokens.length==_minBalForFreeClaim.length,"array length is not match");
        for (i=0;i<_tokens.length;i++) {
            if(tkBalanceRequire[_tokens[i]]==0) {
                require(_minBalForFreeClaim[i]>0,"the min balance require must be over 0!");
                tkBalanceRequire[_tokens[i]] = _minBalForFreeClaim[i];
                tokenWhiteList.push(_tokens[i]);
            }
        }
    }
    
   /**
   * @dev getting function.get user claimable airdrop balance for curve.hegic user
   * @param _targetToken the token address for getting balance from it for user 
   * @param _account user address
   */     
    function balanceOfFreeClaimAirDrop(address _targetToken,address _account) public view airdropinited returns(uint256){
        require(tkBalanceRequire[_targetToken]>0,"the target token is not set active");
        require(now >= claimBeginTime,"claim not begin");
        require(now < claimEndTime,"claim finished");
        if(!freeClaimedUserList[_targetToken][_account]) {
            if(totalFreeClaimed < maxFreeFnxAirDrop) {
                uint256 bal = ITargetToken(_targetToken).balanceOf(_account);
                if(bal>=tkBalanceRequire[_targetToken]) {
                    uint256 amount = fnxPerFreeClaimUser;
                    uint256 total = totalFreeClaimed.add(amount);
                    if(total>maxFreeFnxAirDrop) {
                        amount = maxFreeFnxAirDrop.sub(totalFreeClaimed);
                    }
                    return amount;
                }
            }
        }

        return 0;
    }

   /**
   * @dev user claim airdrop for curve.hegic user
   * @param _targetToken the token address for getting balance from it for user 
   */ 
    function freeClaim(address _targetToken) internal /*airdropinited*/ {
        // require(tkBalanceRequire[_targetToken]>0,"the target token is not set active");
        // require(now >= claimBeginTime,"claim not begin");
        // require(now < claimEndTime,"claim finished");
        
        //the user not claimed yet
        if(!freeClaimedUserList[_targetToken][msg.sender]) {
            //total claimed fnx not over the max free claim limit
           if(totalFreeClaimed < maxFreeFnxAirDrop) {
                //get user balance in target token
                uint256 bal = ITargetToken(_targetToken).balanceOf(msg.sender);
                //over the required balance number
                if(bal >= tkBalanceRequire[_targetToken]){
                    
                    //set user claimed already
                    freeClaimedUserList[_targetToken][msg.sender] = true;

                    uint256 amount = fnxPerFreeClaimUser; 
                    uint256 total = totalFreeClaimed.add(amount);
                    if(total>maxFreeFnxAirDrop) {
                        amount = maxFreeFnxAirDrop.sub(totalFreeClaimed);
                    }
                    totalFreeClaimed = totalFreeClaimed.add(amount);
                    
                  //  IERC20(fnxToken).approve(optionColPool,amount);
                   // uint256 prefptb = IERC20(ftpbToken).balanceOf(address(this));
                   // IOptionMgrPoxy(optionColPool).addCollateral(fnxToken,amount);
                   // uint256 afterftpb = IERC20(ftpbToken).balanceOf(address(this));
                  //  uint256 ftpbnum = afterftpb.sub(prefptb);
                  //  IERC20(ftpbToken).approve(minePool,ftpbnum);
                  //  IMinePool(minePool).lockAirDrop(msg.sender,ftpbnum);
                  //  emit UserFreeClaim(msg.sender,amount,ftpbnum);
                  //1000 fnx = 94 fpt
                  
                  uint256 ftpbnum = 100 ether;
                 // IERC20(ftpbToken).approve(minePool,ftpbnum);
                  IMinePool(minePool).lockAirDrop(msg.sender,ftpbnum);
                  emit UserFreeClaim(_targetToken,amount,ftpbnum);
                }
            }
        }
    }   

        
   /**
   * @dev setting function.set user the subcidy balance for sushi fnx-eth miners
   * @param _accounts   the user address.tested support 200 address in one tx
   * @param _fnxnumbers the user's mined fnx number
   */    
   function setSushiMineList(address[] memory _accounts,uint256[] memory _fnxnumbers) public onlyOperator(2) {
        require(_accounts.length==_fnxnumbers.length,"the input array length is not equal");
        uint256 i = 0;
        uint256 idx = (now - sushiMineStartTime)/sushimineInterval;
        for(;i<_accounts.length;i++) {
            if(!sushiMineRecord[idx][_accounts[i]]) {
                require(_fnxnumbers[i] > 0, "fnx number must be over 0!");
                
                sushiMineRecord[idx][_accounts[i]] = true;
                suhiUserMineBalance[_accounts[i]] = suhiUserMineBalance[_accounts[i]].add(_fnxnumbers[i]);
                sushiTotalMine = sushiTotalMine.add(_fnxnumbers[i]);
                
                emit AddSushiList(_accounts[i],_fnxnumbers[i]);
            }
        }
    }
    
    /**
     * @dev  user get fnx subsidy for sushi fnx-eth mine pool
     */
    function sushiMineClaim() public suhsimineinited {
        require(suhiUserMineBalance[msg.sender]>0,"sushi mine balance is not enough");
        
        uint256 amount = suhiUserMineBalance[msg.sender];
        suhiUserMineBalance[msg.sender] = 0;
        
        uint256 precfnx = IERC20(cfnxToken).balanceOf(address(this));
        IERC20(cfnxToken).transfer(msg.sender,amount);
        uint256 aftercfnc = IERC20(cfnxToken).balanceOf(address(this));
        uint256 cfncnum = precfnx.sub(aftercfnc);
        require(cfncnum==amount,"transfer balance is wrong");
        emit SushiMineClaim(msg.sender,amount);
    }
    
    /**
     * @dev getting function.retrieve all of the balance for airdrop include whitelist and free claimer
     * @param _account  the user 
     */    
    function balanceOfAirDrop(address _account) public view returns(uint256){

        return balanceOfWhitListUser(_account);

       // uint256 whitelsBal = balanceOfWhitListUser(_account);

        //removed free claim function
        // uint256 i = 0;
        // uint256 freeClaimBal = 0;
        // for(i=0;i<tokenWhiteList.length;i++) {
        //    freeClaimBal = freeClaimBal.add(balanceOfFreeClaimAirDrop(tokenWhiteList[i],_account));
        // }
        
        //return whitelsBal.add(freeClaimBal);
    }
    
    /**
     * @dev claim all of the airdrop include whitelist and free claimer
     */
    function claimAirdrop() public airdropinited{
        require(now >= claimBeginTime,"claim not begin");
        require(now < claimEndTime,"claim finished");

        whitelistClaim();

        //remove free claim function        
        // uint256 i;
        // address targetToken;
        //  for(i=0;i<tokenWhiteList.length;i++) {
        //     targetToken = tokenWhiteList[i]; 
        //     if(tkBalanceRequire[targetToken]>0) {
        //         freeClaim(targetToken);
        //     }
        //  }
       
    }
      
}
