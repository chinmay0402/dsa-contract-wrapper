//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

interface Authority {
    function add(address) external payable returns (string memory _eventName, bytes memory _eventParam);
    function remove(address) external payable returns (string memory _eventName, bytes memory _eventParam);
}

interface InstapoolV2 {
    struct AccountData {
        uint ID;
        address account;
        uint version;
        address[] authorities;
    }
    function getAccountAuthorities(address account) external view returns(address[] memory);
    function getAccountIdDetails(uint id) external view returns(AccountData memory);
}

interface ImpDef {
    function isAuth(address user) external returns(bool);
}