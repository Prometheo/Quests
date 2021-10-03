// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;


interface cETH {
    
    // define functions of COMPOUND we'll be using
    
    function mint() external payable; // to deposit to compound
    function redeem(uint redeemTokens) external returns (uint); // to withdraw from compound
    function redeemUnderlying(uint redeemAmount) external returns (uint); // withdraaw underlying assets
    
    //following 2 functions to determine how much you'll be able to withdraw
    function exchangeRateStored() external view returns (uint); 
    function balanceOf(address owner) external view returns (uint256 balance);
}

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

}

interface UniswapRouter {
    function WETH() external pure returns (address);
    
    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    
    function swapExactETHForTokens(
        uint amountOutMin, address[] calldata path, address to, uint deadline
    ) external payable returns (uint[] memory amounts);
    
    function getAmountsIn(uint amountOut, address[] memory path) external view returns (uint[] memory amounts);
}


contract SmartBankAccount {
    uint totalContractBalance = 0;
    
    address COMPOUND_CETH_ADDRESS = 0x859e9d8a4edadfEDb5A2fF311243af80F85A91b8;
    cETH ceth = cETH(COMPOUND_CETH_ADDRESS);
    
    address UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    UniswapRouter uniswap = UniswapRouter(UNISWAP_ROUTER_ADDRESS);
    
    function getContractBalance() public view returns(uint){
        return address(this).balance;
    }
    
    mapping(address => uint) balances;
    mapping(address => uint) test;
    event myVar(uint amountOut);
    
    receive() external payable{}
    
    function addBalance() public payable {
        deposit(msg.value); // deposit to compound
    }
    
    
    // this function then handles depositing funds to compound
    function deposit(uint amount) internal {
        uint256 cEthOfContractBeforeMinting = ceth.balanceOf(address(this)); //this refers to the current contract
        
        // send ethers to mint()
        ceth.mint{value: amount}();
        
        uint256 cEthOfContractAfterMinting = ceth.balanceOf(address(this)); // updated balance after minting
        
        uint cEthOfUser = cEthOfContractAfterMinting - cEthOfContractBeforeMinting; // the difference is the amount that has been created by the mint() function
        balances[msg.sender] += cEthOfUser;
    }
    
    
    // allow user to deposit fund using other tokens aside eth
    function addBalanceERC20(address erc20TokenSmartContractAddress) public returns (bool) {
        IERC20 erc20 = IERC20(erc20TokenSmartContractAddress);
        
        // how many erc20tokens has the user (msg.sender) approved this contract to use?
        uint approvedAmountOfERC20Tokens = erc20.allowance(msg.sender, address(this));
        
        address token = erc20TokenSmartContractAddress;
        uint amountETHMin = 0; 
        address to = address(this);
        uint deadline = block.timestamp;
    
        // transfer all those tokens that had been approved by user (msg.sender) to the smart contract (address(this))
        erc20.transferFrom(msg.sender, address(this), approvedAmountOfERC20Tokens);
        
        erc20.approve(UNISWAP_ROUTER_ADDRESS, approvedAmountOfERC20Tokens); // smart contract approve uniswap router to be able to spend token
        
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = uniswap.WETH();
        uint balanceBefore = address(this).balance; // keep track of contract balance state b4 and after swap 
        uniswap.swapExactTokensForETH(approvedAmountOfERC20Tokens, amountETHMin, path, to, deadline); // change tokens to eth
        uint balanceAfter = address(this).balance;
        deposit(balanceAfter-balanceBefore); // deposit eth to compound
        return true;

        
    }
    
    function getAllowanceERC20(address erc20TokenSmartContractAddress) public view returns(uint){
        IERC20 erc20 = IERC20(erc20TokenSmartContractAddress);
        return erc20.allowance(msg.sender, address(this));
    }
    
    function getBalance(address userAddress) public view returns(uint256) {
        return balances[userAddress] * ceth.exchangeRateStored() / 1e18;
    }
    
    function getContractCethBalance() public view returns(uint256) {
        return ceth.balanceOf(address(this));
    }
    
    
    function getDaiBalance(address userAddress) public view returns(uint256) {
        IERC20 erc20 = IERC20(0xaD6D458402F60fD3Bd25163575031ACDce07538D);
        return erc20.balanceOf(userAddress);
    }
    
    function getCethBalance(address userAddress) public view returns(uint256) {
        return balances[userAddress];
    }
    
    
    
    function getExchangeRate() public view returns(uint256){
        return ceth.exchangeRateStored(); // The current exchange rate as an unsigned integer, scaled by 1 * 10^(18 - 8 + Underlying Token Decimals
    }
    
    function withdrawAll() public payable {
        ceth.redeem(balances[msg.sender]); // redeem user's ceth balnces
        uint256 amountToTransfer = getBalance(msg.sender);
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(amountToTransfer);
    }

    // function withdraws amount specified by user
    function withdraw(uint amount) public returns (bool) {
        require(amount > 0, 'non-zero');
        require(amount <= getBalance(msg.sender), 'insufficient');
        uint totalBefore = getContractCethBalance(); // get contract balance b4 and after to keep track of the amount of ceth withdrawn by user
        require(ceth.redeemUnderlying(amount) == 0, 'failed');
        uint balanceAfter = getContractCethBalance();
        // TODO: keep some percentage profit.
        balances[msg.sender] -= (totalBefore - balanceAfter); // reflect user balance TODO: this my allow for reentrancy, change later.
        payable(msg.sender).transfer(amount);
        return true;
    }
    
    // allow withdrawal to any curency, provided there is liquidity on uniswap
    function withdrawInErc20(uint tokenAmount, address erc20TokenAddress) public returns (uint[] memory amounts) {
        
        require(tokenAmount > 0, 'non-zero');
        address token = erc20TokenAddress;
        address[] memory path = new address[](2);
        path[0] = uniswap.WETH();
        path[1] = token;
        uint equivalentEth = uniswap.getAmountsIn(tokenAmount, path)[0]; // getthe eth equivalent of the token amount passed
        emit myVar(equivalentEth);
        require(equivalentEth <= getBalance(msg.sender), 'insufficient');
        uint totalBefore = getContractCethBalance();// track ceth balance to reflect on user balances
        require(ceth.redeemUnderlying(equivalentEth) == 0, 'failed');
        uint balanceAfter = getContractCethBalance();
        // TODO: keep some percentage profit.
        balances[msg.sender] -= (totalBefore - balanceAfter); // reflect on user balance
        amounts = uniswap.swapExactETHForTokens{value: equivalentEth}(0, path, msg.sender, block.timestamp); // swap the eth to the desired user token and send directly to user
    }
    
    function addMoneyToContract() public payable {
        totalContractBalance += msg.value;
    }
}
