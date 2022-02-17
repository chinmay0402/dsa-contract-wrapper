//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/**
 * @title DsaWrapper
 * @dev Contract to wrap a DSA contract deployed by the user, allows user deposit, withdraw ETH/ERC20 tokens and modify authority
 */

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/InstapoolV2.sol";
import "./interfaces/IDSA.sol";

contract DsaWrapper {
    using SafeERC20 for IERC20;

    address private owner;
    address private authorityContractAddress =
        0x351Bb32e90C35647Df7a584f3c1a3A0c38F31c68;
    address private instapoolV2ContractAddress =
        0x621AD080ad3B839e7b19e040C77F05213AB71524;
    InstapoolV2 instapool = InstapoolV2(instapoolV2ContractAddress); // instantiate instapool contract

    /**
     * @dev returns all authorities of the DSA account having id _id
     * @param _id the id of the DSA account
     * @return array containing all authorities of the account
     */
    function getAuthority(uint256 _id) public view returns (address[] memory) {
        // get dsa-address from id
        address dsaAddress = instapool.getAccountIdDetails(_id).account;

        address[] memory accountAuthorities = instapool.getAccountAuthorities(
            dsaAddress
        );

        return accountAuthorities;
    }

    /**
     * @dev modifier to check if the user trying to perform operation on the DSA is authority
     * @param _id id of DSA account
     * @param _user address of person trying to perform operaion
     */
    modifier onlyAuthority(uint256 _id, address _user) {
        address[] memory authorities = getAuthority(_id);

        bool isAuthority = false;
        for (uint256 i = 0; i < authorities.length; i++) {
            if (authorities[i] == _user) {
                isAuthority = true;
                break;
            }
        }
        require(isAuthority, "PERMISSION DENIED: NO AUTHORITY");
        _;
    }

    /**
     * @dev deposits ETH sent to contract to DSA account given by _id
     * @param _id id of DSA account
     */
    function depositEther(uint256 _id)
        public
        payable
        onlyAuthority(_id, msg.sender)
    {
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

        IDSA(dsaAddress).cast{value: msg.value}(targets, data, address(this));
    }

    /**
     * @dev withdraws ETH from DSA account given by _id
     * @param _id id of DSA account
     * @param _amt amount of ETH to withdraw
     */
    function withdrawEther(uint256 _id, uint256 _amt)
        public
        onlyAuthority(_id, msg.sender)
    {
        address dsaAddress = instapool.getAccountIdDetails(_id).account;
        require(dsaAddress.balance >= _amt, "INSUFFICIENT FUNDS");

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

        IDSA(dsaAddress).cast(targets, data, address(this));
    }

    /**
     * @dev deposits ERC20 token to DSA account given by _id
     * @param _id id of DSA account
     * @param _amt amount of tokens to be deposited
     * @param _tokenAddress address of token to be deposited
     */
    function depositErc20(
        uint256 _id,
        uint256 _amt,
        address _tokenAddress
    ) public onlyAuthority(_id, msg.sender) {
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
        IDSA(dsaAddress).cast(targets, data, address(this));
    }

    /**
     * @dev withdraws ERC20 token from DSA account given by _id
     * @param _id id of DSA account
     * @param _amt amount of tokens to withdraw
     * @param _tokenAddress contract address of ERC20 token
     */
    function withdrawErc20(
        uint256 _id,
        uint256 _amt,
        address _tokenAddress
    ) public onlyAuthority(_id, msg.sender) {
        IERC20 token = IERC20(_tokenAddress);
        
        address dsaAddress = instapool.getAccountIdDetails(_id).account;

        require(token.balanceOf(dsaAddress) >= _amt, "INSUFFICIENT TOKEN BALANCE");

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

        IDSA(dsaAddress).cast(targets, data, address(this));
    }

    /**
     * @dev adds the passed address to the list of authority accounts of the DSA
     * @param _id id of the DSA account
     * @param _authority address of account to be added as authority to DSA
     */
    function addAuthority(uint256 _id, address _authority)
        public
        onlyAuthority(_id, msg.sender)
    {
        require(_authority != address(0), "INVALID ADDRESS");

        address dsaAddress = instapool.getAccountIdDetails(_id).account;
        string[] memory target = new string[](1);
        target[0] = "AUTHORITY-A";

        bytes[] memory data = new bytes[](1);
        bytes4 addAuth = bytes4(keccak256("add(address)"));

        data[0] = abi.encodeWithSelector(addAuth, _authority);
        IDSA(dsaAddress).cast(target, data, address(this));
    }

    /**
     * @dev removes the passed address from the list of authority accounts of the DSA
     * @param _id id of the DSA account
     * @param _authority address of account to be removed from authorities to DSA
     */
    function removeAuthority(uint256 _id, address _authority)
        public
        onlyAuthority(_id, msg.sender)
    {
        require(_authority != address(0), "INVALID ADDRESS");
        
        address[] memory authorities = getAuthority(_id);

        require(authorities.length > 1, "CANNOT REMOVE ALL AUTHORITIES");

        address dsaAddress = instapool.getAccountIdDetails(_id).account;

        string[] memory target = new string[](1);
        target[0] = "AUTHORITY-A";

        bytes[] memory data = new bytes[](1);
        bytes4 removeAuth = bytes4(keccak256("remove(address)"));

        data[0] = abi.encodeWithSelector(removeAuth, _authority);
        IDSA(dsaAddress).cast(target, data, address(this));
    }
}
