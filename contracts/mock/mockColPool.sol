pragma solidity 0.5.16;

import "../ERC20/IERC20.sol";
import "../modules/Ownable.sol";
/**
 * @dev Example of the ERC20 Token.
 */
interface mocktoken {
   function mint(address account, uint256 amount) external;
}
 
contract mockColPool is Ownable{
    address public ftpbToken;
    function addCollateral(address collateral,uint256 amount) external payable{
        require(collateral != address(0));
        require(amount > 0);
        IERC20(collateral).transferFrom(msg.sender,address(this),amount);
        mocktoken(ftpbToken).mint(msg.sender,amount);
    }

    function initialize(address _ftpb)
         public
         onlyOwner
    {
        ftpbToken = _ftpb;
    }
}