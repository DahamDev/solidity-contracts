// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/AccessControl.sol";

contract DahamCOntract is AccessControl {

    bytes32 public constant MINTER = keccak256("MINTER");
    bytes32 public constant MINTER_ADMIN = keccak256("MINTER_ADMIN");
    string returnword="yes";

    constructor(){
        // _setupRole(DEFAULT_ADMIN_ROLE, msg.sender); 
        _setupRole(MINTER_ADMIN,msg.sender);
        _setRoleAdmin(MINTER, MINTER_ADMIN);
    }

    function getValue() external view  onlyRole(MINTER)  returns (string memory){
        return returnword;
    }

    function addMinter(address addr) external{
        grantRole(MINTER,addr);
    }

}