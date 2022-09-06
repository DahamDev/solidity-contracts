// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.16;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract ERC721 is IERC721{

    mapping(address=>uint256) private _balances;

    mapping (uint256=>address) private  _owners;

    mapping (address=>mapping(address=>bool)) _operatorApprovals;

    mapping(uint256 => address) private _tokenApprovals;

    mapping (uint256=>string) private _tokenURI;

    string private _name;
    string private  _symbol;
    string private baseUri;
    string private contractUrl="https://firebasestorage.googleapis.com/v0/b/jsonfile-test-f5ee0.appspot.com/o/samurai.json?alt=media&token=9b0268c8-66c6-455c-8e91-2a66041b65c7";

    uint256 _totalSupply;
    uint8 latestId=1;

    //adding roles of minters 
    // bytes32 public constant MINTER = keccak256("MINTER");
    // bytes32 public constant MASTER_MINTER = keccak256("MINTER_ADMIN");

    // bytes32 public constant ADMIN = keccak256("ADMIN");
    // bytes32 public constant CONTRACT_ADMIN = keccak256("CONTRACT_ADMIN");

    enum TransactionType {Burn,Transfer,Mint}
    TransactionType transactionType ;

    constructor(string memory contract_name,string memory contract_symbol){
        // _setupRole(ADMIN,contract_admin);
        // _setRoleAdmin(CONTRACT_ADMIN, ADMIN);
        _name=contract_name;
        _symbol=contract_symbol;
        _totalSupply=0;
     }

    function baseTokenURI() public view returns (string memory) {
    return baseUri;
    }

    function setBaseTokenURI(string memory uri) public {
        baseUri=uri;
    }

    function totalSupply() external view returns (uint256){
        return _totalSupply;
    }

     //metadata functions
    function name() external view returns (string memory){
        return _name;
    }
    function symbol() external view returns (string memory){
        return _symbol;
    }
    function tokenURI(uint256 tokenId) external view returns (string memory){
        return _tokenURI[tokenId];
    }

    function setTokenURI(uint256 id,string memory uri)  external{ //onlyRole(CONTRACT_ADMIN)
        _tokenURI[id]=uri;
    }

    function contractURI() public view returns (string memory) {
        return contractUrl;
    
    }

    function setContractUrl(string memory url) public {
        contractUrl=url;
    }



    // function addAdmin(address contractAdmin) external{
    //     _grantRole(CONTRACT_ADMIN, contractAdmin);
    // }

    // function addMasterMinter(address masterMinter) external{ //onlyRole(CONTRACT_ADMIN) 
    //     _setupRole(MASTER_MINTER,masterMinter);
    //     _setRoleAdmin(MINTER, MASTER_MINTER);
    // }

    // function addMinter(address minter) external{
    //     require(minter!=address(0),"Zero address cannot be a minter");
    //      grantRole(MINTER,minter);
        
    // }

    function balanceOf(address owner) external view returns (uint256 balance){
        require(owner!=address(0),"owner cannot be zero address");
        return  _balances[owner];
    }
    
    function ownerOf(uint256 tokenId) external view returns (address owner){
        return _owners[tokenId];

    }



    function approve(address to, uint256 tokenId) public virtual override {
        address owner = _owners[tokenId];
            require(to != owner, "ERC721: approval to current owner");
        require(
            msg.sender == owner,
            "ERC721: approve caller is not token owner nor approved for all"
        );
        _approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(msg.sender, operator, approved);
    }


    function transferFrom(address from,address to,uint256 tokenId) public virtual override {
        require(_isApprovedOrOwner(from,tokenId),"Sender is not approved to transfer the token");
        require(to != address(0), "ERC721: transfer to the zero address"); 
         _transfer(from, to, tokenId,TransactionType.Transfer);
    }

    function transfer(address to,uint256 tokenId) external {
        require(_isApprovedOrOwner(msg.sender,tokenId),"Sender is not approved to transfer the token");
        require(to != address(0), "ERC721: transfer to the zero address"); 
        _transfer(msg.sender, to, tokenId,TransactionType.Transfer);
    }

    function safeTransfer(address to, uint256 tokenId,bytes calldata data ) external{
        require(_isApprovedOrOwner(msg.sender,tokenId),"Sender is not approved to transfer the token");
        require(to != address(0), "ERC721: transfer to the zero address"); 
        _safeTransfer(msg.sender, to, tokenId, data);
    }

    function safeTransfer(address to, uint256 tokenId ) external{
        require(_isApprovedOrOwner(msg.sender,tokenId),"Sender is not approved to transfer the token");
        require(to != address(0), "ERC721: transfer to the zero address"); 
         _safeTransfer(msg.sender, to, tokenId,"");
    }

    function safeTransferFrom(address from,address to, uint256 tokenId,bytes calldata data ) external{
        require(_isApprovedOrOwner(from,tokenId),"Sender is not approved to transfer the token");
        require(to != address(0), "ERC721: transfer to the zero address"); 
        _safeTransfer(from, to, tokenId, data);
    }

    function safeTransferFrom(address from,address to, uint256 tokenId) external{
        require(_isApprovedOrOwner(from,tokenId),"Sender is not approved to transfer the token");
        require(to != address(0), "ERC721: transfer to the zero address"); 
        _safeTransfer(from, to, tokenId, "");
    }


    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_owners[tokenId]!=address(0),"token does not exists");
        return _tokenApprovals[tokenId];
    }
    
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    //minting functions 
    function safeMint(address to,uint256 tokenId,bytes memory data)   external returns(uint8) { //onlyRole(MINTER)
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
        return mint(to);
    }

    function mint(address to) public override returns(uint8){ //onlyRole(MINTER) 
        require(to != address(0), "ERC721: mint to the zero address");
        _transfer(msg.sender, to, latestId,TransactionType.Mint);
        _totalSupply+=1;
        latestId+=1;
        return latestId;
        
        
    }

    function burn(address to, uint256 tokenId) public override{
        require(msg.sender==_owners[tokenId],"Unauthorized token burn operation");
        require(_exists(tokenId), "ERC721: token does not exist");
        _transfer(msg.sender, to, tokenId,TransactionType.Burn);
        _totalSupply-=1;
    }

    //internal functions
    function _exists(uint256 tokenId) internal view returns(bool){
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address from, uint256 tokenId) internal view  returns(bool){
        address owner = _owners[tokenId];
        return (from == owner || isApprovedForAll(owner, from) || getApproved(tokenId) == from);
    }

    function _safeTransfer(address from,address to,uint256 tokenId,bytes memory data) internal  {
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
        _transfer(from, to, tokenId,TransactionType.Transfer);
    }


    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(_owners[tokenId], to, tokenId);
    }

    function _transfer(address from,address to,uint256 tokenId,TransactionType _transactionType) internal virtual {
        
        if(_transactionType!=TransactionType.Mint){
            delete _tokenApprovals[tokenId];
            _balances[from] -= 1;
        }
        if(_transactionType!=TransactionType.Burn){
            _balances[to] += 1;
            _owners[tokenId] = to;
        }
 
        emit Transfer(from, to, tokenId);
    }

    function _setApprovalForAll(address owner,address operator,bool approved) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }




    function _checkOnERC721Received(address from,address to,uint256 tokenId,bytes memory data) internal returns (bool) {
        if (_isContract(to)) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            }
            catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } 
                else {
                    /// @solidity memory-safe-assembly
                    assembly {revert(add(32, reason), mload(reason))}
                }
            }
        } else {
            return true;
        }
    }

    function _isContract(address _addr) internal view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
         }
        return (size > 0);
    }
    
}