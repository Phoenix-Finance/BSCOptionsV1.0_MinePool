pragma solidity =0.5.16;

import "../modules/Managerable.sol";
import "../modules/Operator.sol";
import "../modules/Halt.sol";

contract AirDropVaultData is Operator,Halt {

    
    address public optionColPool;//the option manager address
    address public minePool;    //the fixed minePool address
    address public cfnxToken;   //the cfnx toekn address
    address public fnxToken;    //fnx token address
    address public ftpbToken;   //ftpb toekn address
    
    uint256 public totalWhiteListAirdrop; //total ammout for white list seting accounting
    uint256 public totalWhiteListClaimed; //total claimed amount by the user in white list
    uint256 public totalFreeClaimed;      //total claimed amount by the user in curve or hegic
    uint256 public maxWhiteListFnxAirDrop;//the max claimable limit for white list user
    uint256 public maxFreeFnxAirDrop;     // the max claimable limit for hegic or curve user
    
    uint256 public claimBeginTime;  //airdrop start time
    uint256 public claimEndTime;    //airdrop finish time
    uint256 public fnxPerFreeClaimUser; //the fnx amount for each person in curve or hegic


    mapping (address => uint256) public userWhiteList; //the white list user info
    mapping (address => uint256)  public tkBalanceRequire; //target airdrop token list address=>min balance require
    address[] public tokenWhiteList; //the token address for free air drop
    
    //the user which is claimed already for different token
    mapping (address=>mapping(address => bool)) public freeClaimedUserList; //the users list for the user claimed already from curve or hegic
    
    uint256 public sushiTotalMine;  //sushi total mine amount for accounting
    uint256 public sushiMineStartTime; //suhi mine start time
    uint256 public sushimineInterval = 30 days; //sushi mine reward interval time
    mapping (address => uint256) public suhiUserMineBalance; //the user balance for subcidy for sushi mine
    mapping (uint256=>mapping(address => bool)) sushiMineRecord;//the user list which user mine is set already
    
    event AddWhiteList(address indexed claimer, uint256 indexed amount);
    event WhiteListClaim(address indexed claimer, uint256 indexed amount,uint256 indexed ftpbnum);
    event UserFreeClaim(address indexed claimer, uint256 indexed amount,uint256 indexed ftpbnum);
    
    event AddSushiList(address indexed claimer, uint256 indexed amount);
    event SushiMineClaim(address indexed claimer, uint256 indexed amount);
}