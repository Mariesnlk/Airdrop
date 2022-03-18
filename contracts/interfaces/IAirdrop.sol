// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface of the Airdrop contract that use CustomERC20 tokens
 */
interface IAirdrop {
    event Airdroped(
        address indexed from,
        address indexed recipient,
        uint256 amountToSend
    );
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Deposit(address indexed from, address indexed to, uint256 value);
    event Withdraw(address indexed from, address indexed to, uint256 value);
    event Claimed(address indexed from, address indexed to, uint256 value);
    event UpdatedAddress(address indexed updated);

    struct Receipient {
        uint256 claimedAmount;
        bool isClaimed;
    }

    /**
     * @dev Transfer tokens from owner to airdrop contract
     *
     * @param _amount - amount of tokens that should be transferred from owner to contact balance for distribution
     *
     * Emits a {Deposit, Transfer} event.
     */
    function depositTokens(uint256 _amount) external;

    /**
     * @dev Deposit ether to airdrop contract
     *
     * Emits a {Deposit, Transfer} event.
     */
    function depositEther() external payable;

    /**
     * @dev Should set eligible token amounts to recipients. This info should be stored in the mapping.
     * The owner should sign the transaction.
     *
     * Emits a {TokenAirdrop} event.
     */
    function dropTokens(
        address[] memory _recipients,
        uint256[] memory _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    /**
     * @dev Should set eligible ether amounts to recipients. This info should be stored in the mapping.
     * The owner should sign the transaction.
     *
     * Emits a {EtherAirdrop} event.
     */
    function dropEther(
        address[] memory _recipients,
        uint256[] memory _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    /**
     * @dev Update token for airdrop
     *
     * @param _tokenAddress - token address to update fpr airdrop
     *
     * Emits a {UpdatedAddress} event.
     */
    function updateTokenAddress(address _tokenAddress) external;

    /**
     * @dev Transfer all tokens to the owner address
     *
     * Emits a {Withdraw, Transfer} event.
     */
    function withdrawTokens() external;

    /**
     * @dev Transfer all ethers to the owner
     *
     * Emits a {Withdraw} event.
     */
    function withdrawEther() external payable;

    /**
     * @dev Users should be able to claim all their funds if they are eligible.
     * Need to check is user has unclaimed token amount
     *
     * Emits a {Claimed} event.
     */
    function claimToken() external;

    /**
     * @dev Users should be able to claim all their ether if they are eligible.
     * Need to check is user has unclaimed ether amount
     *
     * Emits a {Claimed} event.
     */
    function claimEther() external payable;
}
