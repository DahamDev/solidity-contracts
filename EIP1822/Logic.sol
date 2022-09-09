// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;


import "./Proxiable.sol";

contract LogicContract is Proxiable {

    uint counter;

    function getCounterValue() public view returns(uint){
        return counter;
    }

    function incrementCounter() public{
        counter+=1;
    }

    function decrementCounter() public{
        counter-=1;
    }

    
    function updateCode(address newCode) public {
        updateCodeAddress(newCode);
    }

}