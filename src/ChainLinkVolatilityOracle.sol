// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IVolatilityOracle} from "./IVolatilityOracle.sol";

// https://docs.chain.link/data-feeds/price-feeds/addresses?network=ethereum&page=1
// https://solidity-by-example.org/defi/chainlink-price-oracle/

library ChainLinkOracleEthUsd {
    // ETH-USD 24hr Realized Volatility
    address constant REALIZED_VOLATILITY_24HOURS = 0x31D04174D0e1643963b38d87f26b0675Bb7dC96e;

    // ETH-USD 30-Day Realized Volatility
    address constant REALIZED_VOLATILITY_30DAYS = 0x8e604308BD61d975bc6aE7903747785Db7dE97e2;

    // ETH-USD 7-Day Realized Volatility
    address constant REALIZED_VOLATILITY_7DAYS = 0xF3140662cE17fDee0A6675F9a511aDbc4f394003;
}

/// @title Oracle contract used to query ChainLink oracles for data feeds related to volatility on ETH - USD market
/// @author Jean Cavallera <CJ42>, Hugo Masclet <Hugoo>
/// ETH / USD - Sepolia
contract ChainLinkVolatilityOracle is IVolatilityOracle {
    AggregatorV3Interface internal volatilityFeed24Hours;
    AggregatorV3Interface internal volatilityFeed7Days;
    AggregatorV3Interface internal volatilityFeed30Days;

    constructor() {
        // priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
    }

    function getLatestPrice() public view returns (int256) {
        // (uint80 roundID, int256 price, uint256 startedAt, uint256 timeStamp, uint80 answeredInRound) =
        //     priceFeed.latestRoundData();
        // // for ETH / USD price is scaled up by 10 ** 8
        // return price / 1e8;

        return 3000;
    }

    function realizedVolatility24Hours() external view returns (uint256) {
        // TODO:
    }

    function realizedVolatility7Days() external view returns (uint256) {
        // TODO:
    }

    function realizedVolatility30Days() external view returns (uint256) {
        // TODO:
    }

    function latestTimestamp() external view returns (uint256) {
        return block.timestamp;
    }
}
