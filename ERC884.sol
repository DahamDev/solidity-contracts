// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./IERC884.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract ERC884 is IERC884 , Ownable, Initializable, AccessControl {

    uint256  totalSupply;
    uint256  burntAmount=0;
    uint8  decimals = 0;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bytes32) private verified;
    mapping(address => address) private cancellations;
    mapping(address => uint256) private holderIndices;

    string  name; //these should come from initialize function 
    string  symbol;  //make all the parameters private and define view functions.
    string  version;

    bool constructorFlag=true;
    bool public burnableToken;

    address public lastBurntAccount;
    address public masterMinter;
    address constant private ZERO_ADDRESS = address(0);
    address[] private shareholders;
  
    bytes32 constant private ZERO_BYTES = bytes32(0);
    bytes32 public constant MINTER = keccak256("MINTER");
    bytes32 public constant MINTER_ADMIN = keccak256("MINTER_ADMIN");
    
  

    modifier isShareholder(address addr) {
        require(holderIndices[addr] != 0,"Address owner is not a shareholder");
        _;
    }

    modifier isNotShareholder(address addr) {
        require(holderIndices[addr] == 0,"Address owner is a shareholder");
        _;
    }

    modifier isNotCancelled(address addr) {
        require(cancellations[addr] == ZERO_ADDRESS,"Address is not a cancelled address");
        _;
    }

    modifier isZeroAccount(address addr){
        require(addr!=address(0),"Transfering to the zero account");
        _;
    }

    modifier isMasterMinter(address minter){
        require(minter==masterMinter);
        _;
    }

    function getTotalSupply() external view returns (uint256){
        return totalSupply;
    }
    function getVersion() external view returns (string memory){
        return version;
    }
    function getSymbol() external view returns (string memory){
        return symbol;
    }

    function getBurntAmount() external view returns(uint256){
        return burntAmount;
    }

    function initialize (
        address _masterMinter,
        address _contractadmin,
        bool _burnableToken,
        string  memory _name,
        string memory _symbol,
        string memory _version
        ) external override initializer onlyOwner  {
   
        burnableToken=_burnableToken;
        name = _name;
        symbol = _symbol;
        version= _version;
        _setupRole(DEFAULT_ADMIN_ROLE, _contractadmin);
        _setupRole(MINTER_ADMIN,_masterMinter);
        _setRoleAdmin(MINTER, MINTER_ADMIN);

     }


    function addMinter(address minter) external  {
        grantRole(MINTER,minter);
        emit AddMinter("addminter",msg.sender,minter);
    }

    function removeMinter(address minter) external{
        revokeRole(MINTER,minter);
        emit AddMinter("addminter",msg.sender,minter);
    }
    
    function _transferToken(address recipient, uint amount) internal isZeroAccount(recipient) returns  (bool) {
        require(balanceOf[msg.sender] >= amount);
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function _transferTokenFrom( address from,address recipient,uint amount) internal  isZeroAccount(recipient)  returns(bool) {
        require(allowance[from][msg.sender] >= amount);
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(from, recipient, amount);
        return true;
    }

    function approve(address spender, uint amount) external returns(bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    //mint for the contract owner's account 
    function mint(uint amount) external onlyRole(MINTER)  {
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    //mint for someone elses account
    function minToAddress( uint amount, address receiver) external onlyRole(MINTER){
        require (amount>0,"Cannot mint negative numbe rof tokens ");
        require (verified[receiver] != ZERO_BYTES,"Emtpy receiver address");
        balanceOf[receiver] += amount;
        totalSupply+=amount;
        emit Transfer(receiver, msg.sender, amount);
    }

    //only the owner can burn token. 
    function burn(uint amount) external {
        require(burnableToken);
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        burntAmount+=amount;
        lastBurntAccount=msg.sender;
        emit Transfer(msg.sender, address(0), amount);
    }

    //implementations of ERC884
    function addVerified(address addr, bytes32 hash) external onlyOwner {
        require(addr != ZERO_ADDRESS);
        require(hash != ZERO_BYTES);
        require(verified[addr] == ZERO_BYTES);
        verified[addr] = hash;
        emit VerifiedAddressAdded(addr, hash, msg.sender);
    }

    function removeVerified(address addr) external onlyOwner {
        require(balanceOf[addr] == 0);
        require(verified[addr] != ZERO_BYTES,"Not a verified address");
        verified[addr] = ZERO_BYTES;
        emit VerifiedAddressRemoved(addr, msg.sender);
    }


    function updateVerified(address addr, bytes32 hash) external onlyOwner {
        require(_isVerifiedAddress(addr),"Address is not a verified address");
        require(hash != ZERO_BYTES,"Provided hash is empty");
        bytes32 oldHash = verified[addr];
        require(oldHash!=hash,"Old hash is equal to the new hash");
        verified[addr] = hash;
        emit VerifiedAddressUpdated(addr, oldHash, hash, msg.sender);
    }

    function cancelAndReissue(address original, address replacement) external onlyOwner isShareholder(original) isNotShareholder(replacement) {
        require(_isVerifiedAddress(replacement));
        verified[original] = ZERO_BYTES;
        cancellations[original] = replacement;
        uint256 holderIndex = holderIndices[original] - 1;
        shareholders[holderIndex] = replacement;
        holderIndices[replacement] = holderIndices[original];
        holderIndices[original] = 0;
        balanceOf[replacement] = balanceOf[original];
        balanceOf[original] = 0;
        emit VerifiedAddressSuperseded(original, replacement, msg.sender);
    }

    function isHolder(address addr) external view returns (bool)
    {
        return holderIndices[addr] != 0;
    }

    function transfer(address to, uint256 value) external returns (bool)
    {   
           return _transferToken(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool)
    {   
        require(_isVerifiedAddress(to),"Address is not a verified address");
        return _transferTokenFrom(from, to, value);
    }

    //internal functions for verifications 

    function _isVerifiedAddress(address _addr) internal returns(bool){
        if(_addr!=ZERO_ADDRESS || verified[_addr] != ZERO_BYTES ) return false;
        return true;
    }

}

