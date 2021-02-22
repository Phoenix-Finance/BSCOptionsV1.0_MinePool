pragma solidity 0.5.16;
import "../Token/ERC20.sol";
import "../modules/Ownable.sol";
/**
 * @dev Example of the ERC20 Token.
 */
contract mockMine is Ownable,ERC20{

    address public pftb;
    mapping (address => uint256) public lockedBalances;
    function lockAirDrop(address user,uint256 ftp_b_amount) external {
        require(user != address(0));
        require(ftp_b_amount > 0);
        lockedBalances[user] = lockedBalances[user] + ftp_b_amount;
         ERC20(pftb).transferFrom(msg.sender,address(this),ftp_b_amount);
    }


    function mint(address account, uint256 amount)
        public
        onlyOwner
    {

    }

    function initialize(address _pftb)
         public
         onlyOwner
    {
        pftb = _pftb;
    }
    

}