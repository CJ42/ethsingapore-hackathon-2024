// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVolatilityOracle {
    function realizedVolatility24Hours() external view returns (int256);
    function realizedVolatility7Days() external view returns (int256);
    function realizedVolatility30Days() external view returns (int256);
    function latestTimestamp() external view returns (uint256);
}
