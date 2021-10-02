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


contract SmartBankAccount {


    uint totalContractBalance = 0;
    
    address COMPOUND_CETH_ADDRESS = 0x859e9d8a4edadfEDb5A2fF311243af80F85A91b8;
    cETH ceth = cETH(COMPOUND_CETH_ADDRESS);
    
    function getContractBalance() public view returns(uint){
        return address(this).balance;
    }
    mapping(address => uint) cethBalances; // record of user's compound eth balances
    mapping(address => uint) depositTimestamps;
    
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
        cethBalances[msg.sender] += cEthOfUser;
    }
    
    function getContractCethBalance() public view returns(uint256) {
        return ceth.balanceOf(address(this));
    }
    
    function getBalance(address userAddress) public view returns(uint256) {
        return cethBalances[userAddress] * ceth.exchangeRateStored() / 1e18;
    }
    
    function getExchangeRate() public view returns(uint256){
        return ceth.exchangeRateStored(); // The current exchange rate as an unsigned integer, scaled by 1 * 10^(18 - 8 + Underlying Token Decimals
    }
    
    // allows user withdraw maximum amount
    function withdrawAll() public payable {
        ceth.redeem(cethBalances[msg.sender]); // redeem user's ceth balnces
        uint256 amountToTransfer = getBalance(msg.sender);
        cethBalances[msg.sender] = 0;
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
        cethBalances[msg.sender] -= (totalBefore - balanceAfter); // reflect user balance TODO: this my allow for reentrancy, change later.
        payable(msg.sender).transfer(amount);
        return true;
    }

    function addMoneyToContract() public payable {
        totalContractBalance += msg.value;
    }

    receive() external payable{

    }

    
}
