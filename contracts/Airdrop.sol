// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "./interfaces/IAirdrop.sol";

contract Airdrop is IAirdrop, EIP712, Ownable {
    using SafeERC20 for IERC20;

    bytes32 public constant _CONTAINER_TYPEHASH =
        keccak256("Container(address sender,uint256 deadline)");

    IERC20 public customToken;

    mapping(address => Receipient) public _tokenAmountsToRecipients;
    mapping(address => Receipient) public _etherAmountsToRecipients;

    constructor(IERC20 customToken_) EIP712("Airdrop", "v1") {
        customToken = customToken_;
    }

    /**
     * @dev Transfer tokens from owner to airdrop contract
     *
     * @param _amount - amount of tokens that should be transferred from owner to contact balance for distribution
     *
     * Emits a {Transfer, Deposit} event.
     */
    function depositTokens(uint256 _amount) external override onlyOwner {
        require(
            customToken.balanceOf(msg.sender) >= _amount,
            "Airdrop: Not enough funds"
        );
        customToken.safeTransferFrom(msg.sender, address(this), _amount);

        emit Deposit(msg.sender, address(this), _amount);
    }

    /**
     * @dev Deposit ether to airdrop contract
     *
     * Emits a {Transfer, Deposit} event.
     */
    function depositEther() external payable override onlyOwner {
        emit Deposit(msg.sender, address(this), msg.value);
    }

    /**
     * @dev Should set eligible token amounts to recipients. This info should be stored in the mapping.
     * The owner should sign the transaction.
     *
     * Emits a {Airdroped} event.
     */
    function dropTokens(
        address[] memory _recipients,
        uint256[] memory _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external override onlyOwner {
        require(
            _recipients.length == _amount.length,
            "Airdrop: The length of two arrays is not equal"
        );
        require(_deadline > block.timestamp, "Airdrop: Time out");
        bytes32 structHash = keccak256(
            abi.encode(_CONTAINER_TYPEHASH, msg.sender, _deadline)
        );
        bytes32 digest = _hashTypedDataV4(structHash);
        address messageSigner = ECDSA.recover(digest, _v, _r, _s);
        require(messageSigner == msg.sender, "Airdrop: Not signed by owner");
        for (uint256 i = 0; i < _recipients.length; i++) {
            require(
                _recipients[i] != address(0),
                "Airdrop: recipient can't be zero address"
            );
            _tokenAmountsToRecipients[_recipients[i]].claimedAmount = _amount[i];
            emit Airdroped(msg.sender, _recipients[i], _amount[i]);
        }
    }

    /**
     * @dev Should set eligible ether amounts to recipients. This info should be stored in the mapping.
     * The owner should sign the transaction.
     *
     * Emits a {Airdroped} event.
     */
    function dropEther(
        address[] memory _recipients,
        uint256[] memory _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external override onlyOwner {
        require(
            _recipients.length == _amount.length,
            "Airdrop: The length of two arrays is not equal"
        );
        require(_deadline > block.timestamp, "Airdrop: Time out");
        bytes32 structHash = keccak256(
            abi.encode(_CONTAINER_TYPEHASH, msg.sender, _deadline)
        );
        bytes32 digest = _hashTypedDataV4(structHash);
        address messageSigner = ECDSA.recover(digest, _v, _r, _s);
        require(messageSigner == msg.sender, "Airdrop: Not signed by owner");
        for (uint256 i = 0; i < _recipients.length; i++) {
            require(
                _recipients[i] != address(0),
                "Airdrop: recipient can't be zero address"
            );
            _etherAmountsToRecipients[_recipients[i]].claimedAmount = _amount[i];
            emit Airdroped(msg.sender, _recipients[i], _amount[i]);
        }
    }

    /**
     * @dev Update token for airdrop
     *
     * @param _tokenAddress - token address to update fpr airdrop
     *
     * Emits a {UpdatedAddress} event.
     */
    function updateTokenAddress(address _tokenAddress)
        external
        override
        onlyOwner
    {
        require(
            address(customToken) != _tokenAddress,
            "Airdrop: The same address"
        );
        if (customToken.balanceOf(address(this)) > 0) {
            _withdrawTokens();
        }

        customToken = IERC20(_tokenAddress);

        emit UpdatedAddress(address(customToken));
    }

    /**
     * @dev Transfer all tokens to the owner address
     *
     * Emits a {Transfer, Withdraw} event.
     */
    function withdrawTokens() external override onlyOwner {
        _withdrawTokens();
    }

    /**
     * @dev Transfer all ethers to the owner
     *
     * Emits a {Transfer, Withdraw} event.
     */
    function withdrawEther() external payable override onlyOwner {
        uint256 balanceOfAirdropContract = address(this).balance;
        require(
            balanceOfAirdropContract > 0,
            "Airdrop: Contract doesn`t have enough ethers!"
        );
        (bool success, ) = msg.sender.call{value: balanceOfAirdropContract}("");
        require(success, "Airdrop: Failed to withdraw Ether");

        emit Withdraw(address(this), msg.sender, balanceOfAirdropContract);
    }

    /**
     * @dev Users should be able to claim all their funds if they are eligible.
     * Need to check is user has unclaimed token amount
     *
     * Emits a {Claimed} event.
     */
    function claimToken() external override {
        require(
            _tokenAmountsToRecipients[msg.sender].claimedAmount != 0,
            "Airdrop: you don`t have permission"
        );
        require(
            !_tokenAmountsToRecipients[msg.sender].isClaimed,
            "Airdrop: Tokens is already claimed"
        );
        uint256 claimedAmount = _tokenAmountsToRecipients[msg.sender]
            .claimedAmount;
        require(claimedAmount > 0, "Airdrop: nothing tokens to claim");
        require(
            customToken.balanceOf(address(this)) >= claimedAmount,
            "Airdrop: Contract doesn`t have enough tokens! "
        );
        customToken.safeTransfer(msg.sender, claimedAmount);
        _tokenAmountsToRecipients[msg.sender].isClaimed = true;

        emit Claimed(address(this), msg.sender, claimedAmount);
    }

    /**
     * @dev Users should be able to claim all their ether if they are eligible.
     * Need to check is user has unclaimed ether amount
     *
     * Emits a {Claimed} event.
     */
    function claimEther() external override {
        require(
            _etherAmountsToRecipients[msg.sender].claimedAmount != 0,
            "Airdrop: you don`t have permission"
        );
        require(
            !_etherAmountsToRecipients[msg.sender].isClaimed,
            "Airdrop: Ethers is already claimed"
        );
        uint256 claimedAmount = _etherAmountsToRecipients[msg.sender]
            .claimedAmount;
        require(claimedAmount > 0, "Airdrop: nothing ether to claim");
        require(
            address(this).balance >= claimedAmount,
            "Airdrop: Contract doesn`t have enough ethers! "
        );
        (bool success, ) = msg.sender.call{value: claimedAmount}("");
        require(success, "Airdrop: Failed to claim Ether");

        _etherAmountsToRecipients[msg.sender].isClaimed = true;

        emit Claimed(address(this), msg.sender, claimedAmount);
    }

    function _withdrawTokens() private {
        uint256 balanceOfAirdropContract = customToken.balanceOf(address(this));
        require(
            balanceOfAirdropContract > 0,
            "Airdrop: Contract doesn`t have tokens!"
        );

        customToken.safeTransfer(msg.sender, balanceOfAirdropContract);

        emit Withdraw(address(this), msg.sender, balanceOfAirdropContract);
    }
}
