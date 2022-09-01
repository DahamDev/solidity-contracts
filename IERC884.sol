// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
interface IERC884 {
    function approve(address spender, uint amount) external  returns (bool);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);


    //methods for ERC884
    function addVerified(address addr, bytes32 hash) external;
    function removeVerified(address addr) external;
    function updateVerified(address addr, bytes32 hash) external;
    function cancelAndReissue(address original, address replacement) external;
    function transfer(address to, uint256 value) external returns (bool);
    function isHolder(address addr) external view returns (bool);
    function addMinter(address addr) external;
    function removeMinter(address minter) external;
    function initialize(address _masterMinter,address _contractadmin,bool _burnableToken,string memory _name,string memory _symbol,string memory _version ) external;
    function getTotalSupply() external view returns (uint256);
    function getVersion() external view returns (string memory );
    function getSymbol() external view returns (string memory);
    function getBurntAmount() external view returns(uint256);

   
    event VerifiedAddressAdded(address indexed addr,bytes32 hash,address indexed sender);
    event VerifiedAddressRemoved(address indexed addr, address indexed sender);
    event VerifiedAddressUpdated(address indexed addr,bytes32 oldHash,bytes32 hash,address indexed sender);
    event VerifiedAddressSuperseded(address indexed original,address indexed replacement,address indexed sender);
    event AddMasterMInter(address indexed masterMinter, address indexed sender);
    event AddMinter(string eventstring,address indexed sender, address indexed minter);

}