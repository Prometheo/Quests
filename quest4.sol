// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract MyErc20 {
    string NAME = "UefaToken";
    string SYMBOL = "UFT";
    uint _totalSupply = 10000000 * 1e8;
    uint _mineFee = 10*1e8;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Loud(address azzert, address xender, uint amount);
    event Loew(address azzert, address xender, uint amount);

    
    mapping(address => uint) balances;
    address public deployer;
    uint transferFee = 2; // percentage commision to charge and give to the deployer on each transfer transaction
    mapping(address => mapping(address => uint)) allowances;
    mapping(uint => bool) blockMined;
    uint totalMinted;
    address public uniswapV2Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    
    constructor(){
        deployer = msg.sender; // assign deployer role to the contract creator
        balances[deployer] = 1000000 * 1e8; // mint some to the deployer
        totalMinted += 1000000 * 1e8;
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
            emit Loud(recipient, msg.sender, amount);
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
    
    // a simple mining function so that users can claim certain amount of UFT at certain blocks.
    function mine() public returns(bool success){
        require((totalMinted + _mineFee) <= _totalSupply);
        if(blockMined[block.number]){
            return false;
        }
        blockMined[block.number] = true;
        balances[msg.sender] = balances[msg.sender] + _mineFee;
        totalMinted += _mineFee;
        return true;
    }
    
    
}
