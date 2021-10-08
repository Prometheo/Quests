// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./Power.sol";

contract Bancor is Power {
    uint32 private constant MAX_WEIGHT = 1000000;
    function purchaseTargetAmount(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _reserveWeight,
        uint256 _amount
    ) public view returns (uint256) {
        // validate input
        require(_supply > 0, "ERR_INVALID_SUPPLY");
        require(_reserveBalance > 0, "ERR_INVALID_RESERVE_BALANCE");
        require(_reserveWeight > 0 && _reserveWeight <= MAX_WEIGHT, "ERR_INVALID_RESERVE_WEIGHT");

        // special case for 0 deposit amount
        if (_amount == 0) return 0;

        // special case if the weight = 100%
        if (_reserveWeight == MAX_WEIGHT) return _supply * _amount / _reserveBalance;

        uint256 result;
        uint8 precision;
        uint256 baseN = _amount + _reserveBalance;
        (result, precision) = power(baseN, _reserveBalance, _reserveWeight, MAX_WEIGHT);
        uint256 temp = _supply * result >> precision;
        return temp - _supply;
    }

    /**
     * @dev given a token supply, reserve balance, weight and a sell amount (in the main token),
     * calculates the target amount for a given conversion (in the reserve token)
     *
     * Formula:
     * return = _reserveBalance * (1 - (1 - _amount / _supply) ^ (1000000 / _reserveWeight))
     *
     * @param _supply          liquid token supply
     * @param _reserveBalance  reserve balance
     * @param _reserveWeight   reserve weight, represented in ppm (1-1000000)
     * @param _amount          amount of liquid tokens to get the target amount for
     *
     * @return reserve token amount
     */
    function saleTargetAmount(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _reserveWeight,
        uint256 _amount
    ) public view returns (uint256) {
        // validate input
        require(_supply > 0, "ERR_INVALID_SUPPLY");
        require(_reserveBalance > 0, "ERR_INVALID_RESERVE_BALANCE");
        require(_reserveWeight > 0 && _reserveWeight <= MAX_WEIGHT, "ERR_INVALID_RESERVE_WEIGHT");
        require(_amount <= _supply, "ERR_INVALID_AMOUNT");

        // special case for 0 sell amount
        if (_amount == 0) return 0;

        // special case for selling the entire supply
        if (_amount == _supply) return _reserveBalance;

        // special case if the weight = 100%
        if (_reserveWeight == MAX_WEIGHT) return _reserveBalance * _amount / _supply;

        uint256 result;
        uint8 precision;
        uint256 baseD = _supply - _amount;
        (result, precision) = power(_supply, baseD, MAX_WEIGHT, _reserveWeight);
        uint256 temp1 = _reserveBalance * result;
        uint256 temp2 = _reserveBalance << precision;
        return (temp1 - temp2) / result;
    }
    
    function fundCost(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _reserveRatio,
        uint256 _amount
    ) public view returns (uint256) {
        // validate input
        require(_supply > 0, "ERR_INVALID_SUPPLY");
        require(_reserveBalance > 0, "ERR_INVALID_RESERVE_BALANCE");
        require(_reserveRatio > 1 && _reserveRatio <= MAX_WEIGHT * 2, "ERR_INVALID_RESERVE_RATIO");

        // special case for 0 amount
        if (_amount == 0) return 0;

        // special case if the reserve ratio = 100%
        if (_reserveRatio == MAX_WEIGHT) return (_amount * _reserveBalance - 1) / _supply + 1;

        uint256 result;
        uint8 precision;
        uint256 baseN = _supply + _amount;
        (result, precision) = power(baseN, _supply, MAX_WEIGHT, _reserveRatio);
        uint256 temp = ((_reserveBalance * result - 1) >> precision) + 1;
        return temp - _reserveBalance;
    }

}