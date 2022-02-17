//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/Authority.sol";
import "./interfaces/IDSA.sol";

contract DsaWrapper {
    using SafeERC20 for IERC20;

    address private owner;
    address private authorityContractAddress =
        0x351Bb32e90C35647Df7a584f3c1a3A0c38F31c68;
    address private instapoolV2ContractAddress =
        0x621AD080ad3B839e7b19e040C77F05213AB71524;
    InstapoolV2 instapool = InstapoolV2(instapoolV2ContractAddress); // instantiate instapool contract

    constructor() {
        owner = msg.sender;
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function getAuthority(uint256 _id)
        external
        view
        returns (address[] memory)
    {
        // get dsa-address from id
        address dsaAddress = instapool.getAccountIdDetails(_id).account;

        address[] memory accountAuthorities = instapool.getAccountAuthorities(
            dsaAddress
        );

        return accountAuthorities;
    }

    // deposit ether to dsa
    function depositEther(uint256 _id) external payable {
        // get dsa-address
        address dsaAddress = instapool.getAccountIdDetails(_id).account;

        string[] memory targets = new string[](1);
        targets[0] = "BASIC-A";

        bytes[] memory data = new bytes[](1);
        bytes4 basicDeposit = bytes4(
            keccak256("deposit(address,uint256,uint256,uint256)")
        );

        address tokenAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

        data[0] = abi.encodeWithSelector(
            basicDeposit,
            tokenAddress,
            msg.value,
            0,
            0
        );

        IDSA(dsaAddress).cast{value: msg.value}(targets, data, address(0));
    }

    // withdraw ether from dsa
    function withdrawEther(uint256 _id, uint256 _amt) external {
        address dsaAddress = instapool.getAccountIdDetails(_id).account;

        string[] memory targets = new string[](1);
        targets[0] = "BASIC-A";

        bytes[] memory data = new bytes[](1);
        bytes4 basicWithdraw = bytes4(
            keccak256("withdraw(address,uint256,address,uint256,uint256)")
        );

        address tokenAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

        data[0] = abi.encodeWithSelector(
            basicWithdraw,
            tokenAddress,
            _amt,
            msg.sender,
            0,
            0
        );

        IDSA(dsaAddress).cast(targets, data, address(0));
    }

    function depositErc20(
        uint256 _id,
        uint256 _amt,
        address _tokenAddress
    ) external payable {
        IERC20 token = IERC20(_tokenAddress);

        // get dsa-address
        address dsaAddress = instapool.getAccountIdDetails(_id).account;

        token.safeTransferFrom(msg.sender, address(this), _amt);
        token.safeApprove(dsaAddress, _amt);

        string[] memory targets = new string[](1);
        targets[0] = "BASIC-A";

        bytes[] memory data = new bytes[](1);
        bytes4 basicDeposit = bytes4(
            keccak256("deposit(address,uint256,uint256,uint256)")
        );

        data[0] = abi.encodeWithSelector(
            basicDeposit,
            _tokenAddress,
            _amt,
            0,
            0
        );
        IDSA(dsaAddress).cast(targets, data, address(0));
    }

    // withdraw ether from dsa
    function withdrawErc20(uint256 _id, uint256 _amt, address _tokenAddress) external {
        address dsaAddress = instapool.getAccountIdDetails(_id).account;

        string[] memory targets = new string[](1);
        targets[0] = "BASIC-A";

        bytes[] memory data = new bytes[](1);
        bytes4 basicWithdraw = bytes4(
            keccak256("withdraw(address,uint256,address,uint256,uint256)")
        );

        data[0] = abi.encodeWithSelector(
            basicWithdraw,
            _tokenAddress,
            _amt,
            msg.sender,
            0,
            0
        );

        IDSA(dsaAddress).cast(targets, data, address(0));
    }

    // add authority
    function addAuthority(uint256 _id, address _authority) external {
        address dsaAddress = instapool.getAccountIdDetails(_id).account;

        string[] memory target = new string[](1);
        target[0] = "AUTHORITY-A";

        bytes[] memory data = new bytes[](1);
        bytes4 addAuth = bytes4(keccak256("add(address)"));

        data[0] = abi.encodeWithSelector(addAuth, _authority);
        IDSA(dsaAddress).cast(target, data, address(0));
    }

    // remove authority
    function removeAuthority(uint256 _id, address _authority) external {
        address dsaAddress = instapool.getAccountIdDetails(_id).account;

        string[] memory target = new string[](1);
        target[0] = "AUTHORITY-A";

        bytes[] memory data = new bytes[](1);
        bytes4 removeAuth = bytes4(keccak256("remove(address)"));

        data[0] = abi.encodeWithSelector(removeAuth, _authority);
        IDSA(dsaAddress).cast(target, data, address(0));
    }
}
