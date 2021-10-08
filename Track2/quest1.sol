// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./Bancor.sol";

contract MyErc20 is Bancor {
    
    string NAME = "UefaToken";
    string SYMBOL = "UFT";
    uint _totalSupply;
    // uint _mineFee = 10*1e8;
    uint256 public reserveBalance;
    uint256 public reserveRatio;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Mint(address recipient, uint amount);
    event Loew(address azzert, address xender, uint amount);

    
    mapping(address => uint) balances;
    address public deployer;
    uint transferFee = 2; // percentage commision to charge and give to the deployer on each transfer transaction
    mapping(address => mapping(address => uint)) allowances;
    mapping(uint => bool) blockMined;
    address public uniswapV2Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    
    constructor(uint256 _reserveRatio) payable {
        reserveRatio = _reserveRatio;
        deployer = msg.sender; // assign deployer role to the contract creator
        _mint(deployer, 10000 * 1e8);
        reserveBalance += msg.value;
    }

    function name() public view returns (string memory){
        return NAME;
    }

    function symbol() public view returns (string memory) {
        return SYMBOL;
    }

    function decimals() public pure returns (uint8) {
        return 8;
    }
    
    function ethBalance() public view returns (uint) {
        return address(this).balance;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply; //10M * 10^8 because decimals is 8
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];    
    }
    
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(allowances[_from][msg.sender] >= _value, "ERC20: transfer amount exceeds allowance");
        
        _transfer(_from, _to, _value);
        allowances[_from][msg.sender] -= _value;
        
        
        return true;
    }
    
    
    
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        // If Uniswap is involved in the transaction , we don not want to take fees, as they are probably providing liquidity, we respect that!(also uniswap might throw errors)
        if (msg.sender != uniswapV2Router) { 
            uint fee = amount * transferFee/100;
            require(senderBalance >= amount+fee, "ERC20: not enough for fee");
            balances[sender] = senderBalance - amount+fee;
            balances[deployer] += fee;
        }
        balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }
    
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowances[_owner][_spender];
    }
    
    function mint() public payable {
        require(msg.value > 0, "non-zero");
        // calculate the amount to mint based on the bancor curve formula with the reserve ratio entered during deployment
        uint coinsToBeMinted = purchaseTargetAmount(totalSupply(), reserveBalance, uint32(reserveRatio), msg.value);
        _mint(msg.sender, coinsToBeMinted);
        reserveBalance += msg.value;
    }
    
    function sellToken(uint256 amountInToken) public {
        require(amountInToken > 0, 'non-zero');
        require(balances[msg.sender] >= amountInToken, 'insufficient');
        // calculate the current worth of the tokens in the reserve token in this case eth.
        uint returnAmount = saleTargetAmount(totalSupply(), reserveBalance, uint32(reserveRatio), amountInToken);
        reserveBalance -= returnAmount;
        _burn(msg.sender, amountInToken);
        payable(msg.sender).transfer(returnAmount);
    }
    
    function TokenPrice(uint256 amountInToken) public view returns (uint256 price) {
        price = fundCost(totalSupply(), reserveBalance, uint32(reserveRatio), amountInToken);
    }
    
    function _mint(address recipient, uint amount) internal {
        _totalSupply += amount;
        balances[recipient] += amount;
        emit Mint(recipient, amount);
    }
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }
    
    
}
