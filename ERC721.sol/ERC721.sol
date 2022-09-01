// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.16;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract ERC721 is AccessControl, IERC721 {

    mapping(address=>uint256) private _balances;

    mapping (uint256=>address) private  _owners;

    mapping (address=>mapping(address=>bool)) _operatorApprovals;

    mapping(uint256 => address) private _tokenApprovals;


    //adding roles of minters 
    bytes32 public constant MINTER = keccak256("MINTER");
    bytes32 public constant MASTER_MINTER = keccak256("MINTER_ADMIN");

    bytes32 public constant ADMIN = keccak256("ADMIN");
    bytes32 public constant CONTRACT_ADMIN = keccak256("CONTRACT_ADMIN");

    constructor(address contract_admin){
        _setupRole(ADMIN,contract_admin);
        _setRoleAdmin(CONTRACT_ADMIN, ADMIN);
     }

    function addMasterMinter(address masterMinter) onlyRole(CONTRACT_ADMIN) external{
        _setupRole(MASTER_MINTER,masterMinter);
        _setRoleAdmin(MINTER, MASTER_MINTER);
    }

    function addMinter(address minter) external{
        require(minter!=address(0),"Zero address cannot be a minter");
         grantRole(MINTER,minter);
        
    }

    function balanceOf(address owner) external view returns (uint256 balance){
        require(owner!=address(0),"owner cannot be zero address");
        return  _balances[owner];
    }
    
    function ownerOf(uint256 tokenId) external view returns (address owner){
        require(owner!=address(0),"owners cannot be zero address");
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
         _transfer(from, to, tokenId);
    }

    function transfer(address to,uint256 tokenId) external {
        require(_isApprovedOrOwner(msg.sender,tokenId),"Sender is not approved to transfer the token");
        require(to != address(0), "ERC721: transfer to the zero address"); 
        _transfer(msg.sender, to, tokenId);
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
    function safeMint(address to,uint256 tokenId,bytes memory data) onlyRole(MINTER)  external {
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
        mint(to, tokenId);
    }

    function mint(address to, uint256 tokenId) onlyRole(MINTER) public override{
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");
        _transfer(msg.sender, to, tokenId);
        
        
    }

    function burn(address to, uint256 tokenId) public override{
        require(msg.sender==_owners[tokenId],"Unauthorized token burn operation");
        require(_exists(tokenId), "ERC721: token does not exist");
        _transfer(msg.sender, to, tokenId);
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
        _transfer(from, to, tokenId);
    }


    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(_owners[tokenId], to, tokenId);
    }

    function _transfer(address from,address to,uint256 tokenId) internal virtual {
        delete _tokenApprovals[tokenId];       
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
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