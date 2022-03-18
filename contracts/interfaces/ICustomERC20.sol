// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @dev Interface of the CustomERC20 extends from ERC20 standard as defined in the EIP and some custom functions.
 */
interface ICustomERC20 is IERC20, IERC20Metadata {
    /**
     * @dev Emitted when the new beneficiary is added with reward amount
     */
    event AdddedBeneficiary(address indexed _beneficiary, uint256 _amount);

    /**
     * @dev Emitted when the beneficiary reward amount is decrease
     */
    event BeneficiaryReward(address indexed _beneficiary, uint256 _amount);

    struct Beneficiar {
        uint256 reward;
        bool isClaimed;
    }

    /**
     * @dev Transfer tokens from the owner to the distribution contract
     *
     * Returns tokens amount in contract
     *
     * Emits a {Transfer} event.
     */
    function deposit(uint256 _amount) external;

    /**
     * @dev Add array of beneficaries with their amount.
     *
     * @param _beneficiaries - array of beneficaries
     * @param _amount - array of amount for each beneficiary reward
     *
     * Emits a {AdddedBeneficiary} event.
     */
    function addBeneficiaries(
        address[] memory _beneficiaries,
        uint256[] memory _amount
    ) external;

    /**
     * @dev Add beneficary with amount.
     *
     * @param _beneficiary - a beneficary
     * @param _amount - how much beneficiary reward token amounts is
     *
     * Emits a {AdddedBeneficiary} event.
     */
    function addBeneficiary(address _beneficiary, uint256 _amount) external;

    /**
     * @dev Decrease the amount of rewards for a beneficiary.
     *
     * @param _beneficiary - a beneficary
     * @param _amount - for how much should decrease rewards amount
     *
     * Emits a {BeneficiaryReward} event.
     */
    function decreaseReward(address _beneficiary, uint256 _amount) external;

    /**
     * @dev Transfer amount of reward tokens back to the owner.
     *
     * @param _amount - amount of reward that should be withdrowed
     *
     * Emits a {Transfer} event.
     */
    function emergencyWithdraw(uint256 _amount) external;

    /**
     * @dev Lock/unlock rewards for beneficiary.
     *
     * Emits a {LockedReward} event.
     */
    function lockRewards(bool isLock) external;

    /**
     * @dev Transfer reward tokens to beneficiary. Can be called when reward is not locked.
     *
     * no params
     *
     * Emits a {Transfer} event.
     */
    function claim() external;
}
