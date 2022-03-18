// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ICustomERC20.sol";

contract CustomERC20 is ICustomERC20, Ownable {
    mapping(address => Beneficiar) public beneficiaries;
    bool public isLocked;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_
    ) {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = totalSupply_;
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() external view override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Total number of tokens in existence
     */
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param _account The address to query the balance of.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address _account)
        external
        view
        override
        returns (uint256)
    {
        return balances[_account];
    }

    function allowance(address _account, address spender)
        external
        view
        override
        returns (uint256)
    {
        return allowed[_account][spender];
    }

    function decimals() external pure virtual override returns (uint8) {
        return 0;
    }

    /**
     * @dev Transfer token for a specified address
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(address to, uint256 value)
        external
        override
        returns (bool)
    {
        require(
            value <= balances[msg.sender],
            "ERC20: Transfer more value than msg.sender balance"
        );

        _transfer(msg.sender, to, value);

        return true;
    }

    function approve(address spender, uint256 value)
        external
        override
        returns (bool)
    {
        require(spender != address(0));

        allowed[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override returns (bool) {
        require(
            value <= balances[from],
            "ERC20: transfer more value than balance from address"
        );
        require(
            value <= allowed[from][msg.sender],
            "ERC20: allowed value is less than "
        );

        _transfer(from, to, value);
        allowed[from][msg.sender] -= value;

        return true;
    }

    /**
     * @dev Transfer tokens from the owner to the distribution contract
     *
     * Returns tokens amount in contract
     *
     * Emits a {Transfer} event.
     */
    function deposit(uint256 _amount) external override onlyOwner {
        require(balances[msg.sender] >= _amount, "Not enough funds");
        _transfer(msg.sender, address(this), _amount);
    }

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
    ) external override onlyOwner {
        require(
            _beneficiaries.length == _amount.length,
            "The length of two arrays is not equal"
        );
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            _addBeneficiary(_beneficiaries[i], _amount[i]);
        }
    }

    /**
     * @dev Add beneficary with amount.
     *
     * @param _beneficiary - a beneficary
     * @param _amount - how much beneficiary reward token amounts is
     *
     * Emits a {AdddedBeneficiary} event.
     */
    function addBeneficiary(address _beneficiary, uint256 _amount)
        external
        override
        onlyOwner
    {
        _addBeneficiary(_beneficiary, _amount);
    }

    /**
     * @dev Decrease the amount of rewards for a beneficiary.
     *
     * @param _beneficiary - a beneficary
     * @param _amount - for how much should decrease rewards amount
     *
     * Emits a {BeneficiaryReward} event.
     */
    function decreaseReward(address _beneficiary, uint256 _amount)
        external
        override
        onlyOwner
    {
        require(
            beneficiaries[_beneficiary].reward != 0,
            "Beneficiary is not exists"
        );
        require(
            !beneficiaries[_beneficiary].isClaimed,
            "Reward tokens is already withdrawn"
        );
        uint256 _reward = beneficiaries[_beneficiary].reward;
        require(
            _reward > _amount,
            "Beneficiary reward amount is less or equals zero"
        );

        beneficiaries[_beneficiary].reward -= _amount;
        emit BeneficiaryReward(_beneficiary, _reward);
    }

    /**
     * @dev Transfer amount of reward tokens back to the owner.
     *
     * @param _amount - amount of reward that should be withdrowed
     *
     * Emits a {Transfer} event.
     */
    function emergencyWithdraw(uint256 _amount) external override onlyOwner {
        require(
            balances[address(this)] >= _amount,
            "Contract doesn`t have enough money! "
        );
        _transfer(address(this), msg.sender, _amount);
    }

    /**
     * @dev Lock/unlock rewards for beneficiary.
     *
     * Emits a {LockedReward} event.
     */
    function lockRewards(bool isLock) external override onlyOwner {
        isLocked = isLock;
    }

    /**
     * @dev Transfer reward tokens to beneficiary. Can be called when reward is not locked.
     *
     * no params
     *
     * Emits a {Transfer} event.
     */
    function claim() external override {
        require(!isLocked, "Reward is locked");
        require(
            !beneficiaries[msg.sender].isClaimed,
            "Reward tokens is already withdrawn"
        );
        uint256 _reward = beneficiaries[msg.sender].reward;
        require(_reward != 0, "Reward is zero");
        require(
            balances[address(this)] >= _reward,
            "Contract doesn`t have enough money! "
        );
        _transfer(address(this), msg.sender, _reward);
        beneficiaries[msg.sender].isClaimed = true;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            balances[from] = fromBalance - amount;
        }
        balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _addBeneficiary(address _beneficiary, uint256 _amount) private {
        require(
            beneficiaries[_beneficiary].reward == 0,
            "Beneficiary is already added"
        );
        beneficiaries[_beneficiary].reward = _amount;
        emit AdddedBeneficiary(_beneficiary, _amount);
    }
}