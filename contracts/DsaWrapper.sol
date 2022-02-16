//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/Authority.sol";
import "./interfaces/IDSA.sol";

contract DsaWrapper {

    address private owner;
    address private authorityContractAddress = 0x351Bb32e90C35647Df7a584f3c1a3A0c38F31c68;
    address private instapoolV2ContractAddress = 0x621AD080ad3B839e7b19e040C77F05213AB71524;
    InstapoolV2 instapool = InstapoolV2(instapoolV2ContractAddress); // instantiate instapool contract

    constructor() {
        owner = msg.sender;
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function getAuthority(uint256 _id) view external returns (address[] memory) {
        // get dsa-address from id        
        address dsaAddress = instapool.getAccountIdDetails(_id).account;

        address[] memory accountAuthorities = instapool.getAccountAuthorities(dsaAddress);

        return accountAuthorities;
    }

    // deposit ether to dsa
    function depositEtherToDsa(uint256 _id) external payable {
        // get dsa-address
        address dsaAddress = instapool.getAccountIdDetails(_id).account;

        string[] memory targets = new string[](1);
        targets[0] = "BASIC-A";

        bytes[] memory data = new bytes[](1);
        bytes4 basicDeposit = bytes4(keccak256("deposit(address,uint256,uint256,uint256)"));

        address tokenAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

        data[0] = abi.encodeWithSelector(basicDeposit, tokenAddress, msg.value, 0, 0);

        IDSA(dsaAddress).cast(targets, data, address(0));
    }

    // withdraw ether/erc20 from dsa

    // add authority

    // remove authority

}