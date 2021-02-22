pragma solidity =0.5.16;
import "./AirdropVaultData.sol";
import "../Proxy/baseProxy.sol";


contract AirDropVaultProxy is AirDropVaultData,baseProxy {
    
    constructor (address implementation_) baseProxy(implementation_) public{
    }
    
    function balanceOfWhitListUser(address /*_account*/) public view returns (uint256)  {
        delegateToViewAndReturn();   
    }
    
    function initAirdrop( address /*_optionColPool*/,
                          address /*_minePool*/,
                          address /*_fnxToken*/,
                          address /*_ftpbToken*/,
                          uint256 /*_claimBeginTime*/,
                          uint256 /*_claimEndTime*/,
                          uint256 /*_fnxPerFreeClaimUser*/,
                          uint256 /*_maxFreeFnxAirDrop*/,
                          uint256 /*_maxWhiteListFnxAirDrop*/) public {
        delegateAndReturn();
    }
    
    function initSushiMine( address /*_cfnxToken*/,
                            uint256 /*_sushiMineStartTime*/,
                            uint256 /*_sushimineInterval*/) public  {
       delegateAndReturn();
    }
    
    function getbackLeftFnx(address /*_reciever*/)  public {
        delegateAndReturn();
     }
     

    function setWhiteList(address[] memory /*_accounts*/,uint256[] memory /*_fnxnumbers*/) public {
        delegateAndReturn();
    }
    
    
    function whitelistClaim() public {
        delegateAndReturn();
    }
    
    function setTokenList(address[] memory /*_tokens*/,uint256[] memory /*_minBalForFreeClaim*/) public {
         delegateAndReturn();
    }
    
    function balanceOfFreeClaimAirDrop(address/* _targetToken*/,address/* account*/) public view returns(uint256) {
          delegateToViewAndReturn();
    }
    
    function freeClaim(address /*_targetToken*/) public {
         delegateAndReturn();
    }
    
    function setSushiMineList(address[] memory /*_accounts*/,uint256[] memory /*_fnxnumbers*/) public {
         delegateAndReturn();
    }
    
    function sushiMineClaim() external {
          delegateAndReturn();
    }
    
    function balanceOfAirDrop(address /*_account*/) public view returns(uint256){
          delegateToViewAndReturn();      
    }
    
    function claimAirdrop() public{
          delegateAndReturn();
    }
    
    function resetTokenList()  public {
          delegateAndReturn();
    }
    
}
