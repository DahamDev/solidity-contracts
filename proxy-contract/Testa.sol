// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

contract Contracta{

    int value=0;
    event IncreasedValue(int indexed value, string indexed topic);

    function increase() external {
        value+=1;
        emit IncreasedValue(value,"value got increased");
    }

    function getValue() external view returns(int){
        return value;
    }

}