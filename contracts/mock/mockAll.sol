pragma solidity 0.5.16;
import "../Token/ERC20.sol";
import "../modules/Ownable.sol";
/**
 * @dev Example of the ERC20 Token.
 */
contract mockAll is Ownable,ERC20{
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
    
    address public pftb;
    mapping (address => uint256) public lockedBalances;
    mapping (address => uint256) public userInfoMapA;
    mapping (address => uint256) public userInfoMapB;    
    mapping (address => uint256) public userInfoMap;
  
    function lockAirDrop(address user,uint256 ftp_b_amount) external {
        lockedBalances[user] = ftp_b_amount;
        emit LockAirDrop(msg.sender,address(this),ftp_b_amount);
    }

    function mint(address account, uint256 amount)
        public
        onlyOwner
    {
        _mint(account,amount);
    }

    function initialize(address _pftb)
         public
         onlyOwner
    {
        pftb = _pftb;
    }
    
    function getUserCurrentAPY(address account,address mineCoin)public view returns (uint256) {
        return 10;
    }  
    
    
    function stakeFPTB(uint256 amount,uint256 lockedPeriod)public{
          userInfoMapB[msg.sender] = amount;
          emit  StakeFPTB(msg.sender,amount,lockedPeriod);
    }
    
    function stakeFPTA(uint256 amount)public {
          userInfoMapA[msg.sender] = amount;
          emit StakeFPTA(msg.sender,amount);
    }
    
    function getPrice(address asset) public view returns (uint256) {
        return 1 ether;
    }
    
    function getUserFPTABalance(address account)public view returns (uint256) {
        return userInfoMapA[account];
    }

    function getUserFPTBBalance(address account)public view returns (uint256) {
        return userInfoMapB[account];
    }    
    
    function getTokenNetworth() public view returns (uint256){
        return 1 ether;
    }
    
    function getUserMaxPeriodId(address account)public view returns (uint256) {
        return 1;
    }
    
    function getUserExpired(address account)public view returns (uint256) {
        return now + 3600*24;
    }

}