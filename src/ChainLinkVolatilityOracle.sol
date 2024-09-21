// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// interfaces
import {AggregatorV3Interface} from "foundry-chainlink-toolkit/src/interfaces/feeds/AggregatorV3Interface.sol";
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
        volatilityFeed24Hours = AggregatorV3Interface(ChainLinkOracleEthUsd.REALIZED_VOLATILITY_24HOURS);
        volatilityFeed7Days = AggregatorV3Interface(ChainLinkOracleEthUsd.REALIZED_VOLATILITY_30DAYS);
        volatilityFeed30Days = AggregatorV3Interface(ChainLinkOracleEthUsd.REALIZED_VOLATILITY_7DAYS);
    }

    function realizedVolatility24Hours() external view returns (int256) {
        // Ignore the other returned values as we just need the feed answer (commented for brievity)
        (, int256 volatility24Hours,,,) = volatilityFeed24Hours.latestRoundData();

        return volatility24Hours;
    }

    function realizedVolatility7Days() external view returns (int256) {
        // Ignore the other returned values as we just need the feed answer (commented for brievity)
        (, int256 volatility7Days,,,) = volatilityFeed7Days.latestRoundData();

        return volatility7Days;
    }

    function realizedVolatility30Days() external view returns (int256) {
        // Ignore the other returned values as we just need the feed answer (commented for brievity)
        (, int256 volatility30Days,,,) = volatilityFeed30Days.latestRoundData();

        return volatility30Days;
    }

    function latestTimestamp() external view returns (uint256) {
        return block.timestamp;
    }
}
