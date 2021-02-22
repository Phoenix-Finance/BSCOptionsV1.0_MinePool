pragma solidity =0.5.16;

import "../modules/Ownable.sol";

interface IColPool {
    function getUserPayingUsd(address _user) external view returns (uint256);
}

contract PoolAdapter is Ownable{
    
    address public optionColPool = 0x120f18F5B8EdCaA3c083F9464c57C11D81a9E549;
 
    function setColPool(address _optionColPool) public onlyOwner {
        optionColPool = _optionColPool;
    }
    
    //return value is N e26 (6 is for usd price,18 is for wei)
    function balanceOf(address _account) external view returns (uint256){
        return IColPool(optionColPool).getUserPayingUsd(_account);
    }
}