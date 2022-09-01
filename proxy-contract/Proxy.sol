// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

contract Proxy {
// Code position in storage is keccak256("PROXIABLE") = "0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7"

    function upgradeDelegate(address newDelegateAddress) public {
         assembly { 
            sstore(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7, newDelegateAddress)}
    }

    function getDelegate() external view returns(address) {
        assembly{
            let _target := sload(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7)
            mstore(0x0, _target) 
            return(0x0,0x20)
        }
    }


    fallback () external payable {
        assembly {
            let _target := sload(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7)
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _target, ptr, calldatasize(), 0x0, 0)
            returndatacopy(0x0, 0x0, returndatasize())
            switch result case 0 {revert(0, 0)} default {return (0, returndatasize())}
        }
    }
}