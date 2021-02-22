pragma solidity =0.5.16;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}




interface IOptionMgrPoxy {
    function addCollateral(address collateral,uint256 amount) external payable;
}

interface IMinePool {
    function lockAirDrop(address user,uint256 ftp_b_amount) external;
}

interface ITargetToken {
     function balanceOf(address account) external view returns (uint256);
}


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Managerable is Ownable {

    address private _managerAddress;
    /**
     * @dev modifier, Only manager can be granted exclusive access to specific functions. 
     *
     */
    modifier onlyManager() {
        require(_managerAddress == msg.sender,"Managerable: caller is not the Manager");
        _;
    }
    /**
     * @dev set manager by owner. 
     *
     */
    function setManager(address managerAddress)
    public
    onlyOwner
    {
        _managerAddress = managerAddress;
    }
    /**
     * @dev get manager address. 
     *
     */
    function getManager()public view returns (address) {
        return _managerAddress;
    }
}

pragma solidity >=0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * FinNexus
 * Copyright (C) 2020 FinNexus Options Protocol
 */
    /**
     * @dev Implementation of a whitelist which filters a eligible uint32.
     */
library whiteListUint32 {
    /**
     * @dev add uint32 into white list.
     * @param whiteList the storage whiteList.
     * @param temp input value
     */

    function addWhiteListUint32(uint32[] storage whiteList,uint32 temp) internal{
        if (!isEligibleUint32(whiteList,temp)){
            whiteList.push(temp);
        }
    }
    /**
     * @dev remove uint32 from whitelist.
     */
    function removeWhiteListUint32(uint32[] storage whiteList,uint32 temp)internal returns (bool) {
        uint256 len = whiteList.length;
        uint256 i=0;
        for (;i<len;i++){
            if (whiteList[i] == temp)
                break;
        }
        if (i<len){
            if (i!=len-1) {
                whiteList[i] = whiteList[len-1];
            }
            whiteList.length--;
            return true;
        }
        return false;
    }
    function isEligibleUint32(uint32[] memory whiteList,uint32 temp) internal pure returns (bool){
        uint256 len = whiteList.length;
        for (uint256 i=0;i<len;i++){
            if (whiteList[i] == temp)
                return true;
        }
        return false;
    }
    function _getEligibleIndexUint32(uint32[] memory whiteList,uint32 temp) internal pure returns (uint256){
        uint256 len = whiteList.length;
        uint256 i=0;
        for (;i<len;i++){
            if (whiteList[i] == temp)
                break;
        }
        return i;
    }
}
    /**
     * @dev Implementation of a whitelist which filters a eligible uint256.
     */
library whiteListUint256 {
    // add whiteList
    function addWhiteListUint256(uint256[] storage whiteList,uint256 temp) internal{
        if (!isEligibleUint256(whiteList,temp)){
            whiteList.push(temp);
        }
    }
    function removeWhiteListUint256(uint256[] storage whiteList,uint256 temp)internal returns (bool) {
        uint256 len = whiteList.length;
        uint256 i=0;
        for (;i<len;i++){
            if (whiteList[i] == temp)
                break;
        }
        if (i<len){
            if (i!=len-1) {
                whiteList[i] = whiteList[len-1];
            }
            whiteList.length--;
            return true;
        }
        return false;
    }
    function isEligibleUint256(uint256[] memory whiteList,uint256 temp) internal pure returns (bool){
        uint256 len = whiteList.length;
        for (uint256 i=0;i<len;i++){
            if (whiteList[i] == temp)
                return true;
        }
        return false;
    }
    function _getEligibleIndexUint256(uint256[] memory whiteList,uint256 temp) internal pure returns (uint256){
        uint256 len = whiteList.length;
        uint256 i=0;
        for (;i<len;i++){
            if (whiteList[i] == temp)
                break;
        }
        return i;
    }
}
    /**
     * @dev Implementation of a whitelist which filters a eligible address.
     */
library whiteListAddress {
    // add whiteList
    function addWhiteListAddress(address[] storage whiteList,address temp) internal{
        if (!isEligibleAddress(whiteList,temp)){
            whiteList.push(temp);
        }
    }
    function removeWhiteListAddress(address[] storage whiteList,address temp)internal returns (bool) {
        uint256 len = whiteList.length;
        uint256 i=0;
        for (;i<len;i++){
            if (whiteList[i] == temp)
                break;
        }
        if (i<len){
            if (i!=len-1) {
                whiteList[i] = whiteList[len-1];
            }
            whiteList.length--;
            return true;
        }
        return false;
    }
    function isEligibleAddress(address[] memory whiteList,address temp) internal pure returns (bool){
        uint256 len = whiteList.length;
        for (uint256 i=0;i<len;i++){
            if (whiteList[i] == temp)
                return true;
        }
        return false;
    }
    function _getEligibleIndexAddress(address[] memory whiteList,address temp) internal pure returns (uint256){
        uint256 len = whiteList.length;
        uint256 i=0;
        for (;i<len;i++){
            if (whiteList[i] == temp)
                break;
        }
        return i;
    }
}
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * each operator can be granted exclusive access to specific functions.
 *
 */
contract Operator is Ownable {
    mapping(uint256=>address) private _operators;
    /**
     * @dev modifier, Only indexed operator can be granted exclusive access to specific functions. 
     *
     */
    modifier onlyOperator(uint256 index) {
        require(_operators[index] == msg.sender,"Operator: caller is not the eligible Operator");
        _;
    }
    /**
     * @dev modify indexed operator by owner. 
     *
     */
    function setOperator(uint256 index,address addAddress)public onlyOwner{
        _operators[index] = addAddress;
    }
    function getOperator(uint256 index)public view returns (address) {
        return _operators[index];
    }
}

contract Halt is Ownable {

    bool private halted = false;

    modifier notHalted() {
        require(!halted,"This contract is halted");
        _;
    }

    modifier isHalted() {
        require(halted,"This contract is not halted");
        _;
    }

    /// @notice function Emergency situation that requires
    /// @notice contribution period to stop or not.
    function setHalt(bool halt)
    public
    onlyOwner
    {
        halted = halt;
    }
}

contract AirDropVaultData is Operator,Halt {

    
    address public optionColPool;
    address public minePool;
    address public cfnxToken;
    address public fnxToken;
    address public ftpbToken;
    
    uint256 public totalWhiteListAirdrop;
    uint256 public totalWhiteListClaimed;
    uint256 public totalFreeClaimed;
    uint256 public maxWhiteListFnxAirDrop;
    uint256 public maxFreeFnxAirDrop;
    
    uint256 public claimBeginTime;
    uint256 public claimEndTime;
    uint256 public fnxPerFreeClaimUser;

    //users in white list airdrop
    mapping (address => uint256) public userWhiteList;
    //target airdrop token list address=>min balance require
    mapping (address => uint256)  public tokenWhiteList;
    //the user which is claimed already for different token
    mapping (address=>mapping(address => bool)) public freeClaimedUserList;
    
    uint256 public sushiTotalMine;
    uint256 public sushiMineStartTime;
    uint256 public sushimineInterval = 30 days;
    mapping (address => uint256) public suhiUserMineBalance;
    mapping (uint256=>mapping(address => bool)) sushiMineRecord;
    
    event AddWhiteList(address indexed claimer, uint256 indexed amount);
    event WhiteListClaim(address indexed claimer, uint256 indexed amount,uint256 indexed ftpbnum);
    event UserFreeClaim(address indexed claimer, uint256 indexed amount,uint256 indexed ftpbnum);
    
    event AddSushiList(address indexed claimer, uint256 indexed amount);
    event SushiMineClaim(address indexed claimer, uint256 indexed amount);
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
    
    function update() onlyOwner public{ }
    
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
    }
    
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
        IERC20(fnxToken).transfer(_reciever,bal);
    }  

    /**
     * @dev Retrieve user's locked balance. 
     * @param _account user's account.
     */ 
    function balanceOfWhitListUser(address _account) public view returns (uint256) {
        return userWhiteList[_account];
    }


    function setWhiteList(address[] memory _accounts,uint256[] memory _fnxnumbers) public onlyOperator(1) {
        require(_accounts.length==_fnxnumbers.length,"the input array length is not equal");
        uint256 i = 0;
        for(;i<_accounts.length;i++) {
            userWhiteList[_accounts[i]] = _fnxnumbers[i];
            totalWhiteListAirdrop = totalWhiteListAirdrop.add(_fnxnumbers[i]);
            emit AddWhiteList(_accounts[i],_fnxnumbers[i]);
        }
    }
    
    
    function whitelistClaim() public airdropinited {
        require(userWhiteList[msg.sender]>0,"user balance is not enough");
        require(now >= claimBeginTime,"claim not begin");
        require(now < claimEndTime,"claim finished");
        
        uint256 amount = userWhiteList[msg.sender];
        userWhiteList[msg.sender] = 0;
        totalWhiteListClaimed = totalWhiteListClaimed.add(amount);
        require(totalWhiteListClaimed<=maxWhiteListFnxAirDrop,"total claim amount over max whitelist airdrop");
        
        IERC20(fnxToken).approve(optionColPool,amount);
        uint256 prefptb = IERC20(ftpbToken).balanceOf(address(this));
        IOptionMgrPoxy(optionColPool).addCollateral(fnxToken,amount);
        uint256 afterftpb = IERC20(ftpbToken).balanceOf(address(this));
        uint256 ftpbnum = afterftpb.sub(prefptb);
        IERC20(ftpbToken).approve(minePool,ftpbnum);
        
        IMinePool(minePool).lockAirDrop(msg.sender,ftpbnum);

        emit WhiteListClaim(msg.sender,amount,ftpbnum);
    }
    
    function setTokenList(address[] memory _tokens,uint256[] memory _minBalForFreeClaim) public onlyOwner {
        uint256 i = 0;
        for(i=0;i<_tokens.length;i++) {
            tokenWhiteList[_tokens[i]] = _minBalForFreeClaim[i];
        }
    }

    function freeClaim(address _targetToken) public airdropinited {
        require(tokenWhiteList[_targetToken]>0,"the target token is not set active");
        require(now >= claimBeginTime,"claim not begin");
        require(now < claimEndTime,"claim finished");
        require(!freeClaimedUserList[_targetToken][msg.sender],"user claimed airdrop already");
  
        
        uint256 bal = ITargetToken(_targetToken).balanceOf(msg.sender);
        require(bal>=tokenWhiteList[_targetToken],"user balance in target token is not reach minum require");
        
        totalFreeClaimed = totalFreeClaimed.add(fnxPerFreeClaimUser);
        require(totalFreeClaimed<=maxFreeFnxAirDrop,"total claim amount over max free claim airdrop");
        
        IERC20(fnxToken).approve(optionColPool,fnxPerFreeClaimUser);
        
        uint256 prefptb = IERC20(ftpbToken).balanceOf(address(this));
        IOptionMgrPoxy(optionColPool).addCollateral(fnxToken,fnxPerFreeClaimUser);
        uint256 afterftpb = IERC20(ftpbToken).balanceOf(address(this));
        uint256 ftpbnum = afterftpb.sub(prefptb);
        
        IERC20(ftpbToken).approve(minePool,ftpbnum);
        IMinePool(minePool).lockAirDrop(msg.sender,ftpbnum);

        emit UserFreeClaim(msg.sender,fnxPerFreeClaimUser,ftpbnum);
    }   
    
   
   function setSushiMineList(address[] memory _accounts,uint256[] memory _fnxnumbers) public onlyOperator(1) {
        require(_accounts.length==_fnxnumbers.length,"the input array length is not equal");
        uint256 i = 0;
        uint256 idx = (now - sushiMineStartTime)/sushimineInterval;
        for(;i<_accounts.length;i++) {
            require((!sushiMineRecord[idx][_accounts[i]]),"user's mine have been set already");
            sushiMineRecord[idx][_accounts[i]] = true;
            
            suhiUserMineBalance[_accounts[i]] = suhiUserMineBalance[_accounts[i]].add(_fnxnumbers[i]);
            sushiTotalMine = sushiTotalMine.add(_fnxnumbers[i]);
            
            emit AddSushiList(_accounts[i],_fnxnumbers[i]);
        }
    }
    
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
      
}
