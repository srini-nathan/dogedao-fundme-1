// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC20F is Context, Ownable, IERC20Metadata {
    bool private _paused;

    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint256 private _fee;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 fee_
    ) {
        _name = name_;
        _symbol = symbol_;
        _fee = fee_;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "DDToken: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "DDToken: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function setFeePercentage(uint256 fee_) public onlyOwner {
        require(fee_ > 0 && fee_ < 1000, "DDToken: fee percentage must be less than 10%");
        _fee = fee_;
    }

    function calculateFee(uint256 amount) public view returns (uint256, uint256) {
        require(amount > 10000, "DDToken: transfer amount is too small");

        uint256 receiveal = amount;
        uint256 fee = amount * _fee / 10000;

        unchecked {
            receiveal = amount - fee;
        }

        return (receiveal, fee);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal whenNotPaused returns (uint256) {
        require(sender != address(0), "DDToken: transfer from the zero address");
        require(recipient != address(0), "DDToken: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "DDToken: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }

        uint256 receiveal;
        uint256 fee;

        (receiveal, fee) = calculateFee(amount);

        _balances[recipient] += receiveal;

        emit Transfer(sender, recipient, receiveal);

        return fee;
    }

    function _mint(address account, uint256 amount) internal whenNotPaused {
        require(account != address(0), "DDToken: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal whenNotPaused {
        require(account != address(0), "DDToken: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "DDToken: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal whenNotPaused {
        require(owner != address(0), "DDToken: approve from the zero address");
        require(spender != address(0), "DDToken: approve to the zero address");

        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function pause() public onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function unpause() public onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    event Paused(address account);
    event Unpaused(address account);
}
