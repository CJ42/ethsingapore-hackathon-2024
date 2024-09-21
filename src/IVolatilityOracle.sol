// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVolatilityOracle {
    function realizedVolatility() external view returns (uint256);
    function latestTimestamp() external view returns (uint256);
}
