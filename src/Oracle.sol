// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// https://docs.chain.link/data-feeds/price-feeds/addresses?network=ethereum&page=1
// https://solidity-by-example.org/defi/chainlink-price-oracle/

/// @title Mock Oracle contract used to simulate calls to Oracle protocol
/// @author Jean Cavallera <CJ42>, Hugo Masclet <Hugoo>
contract Oracle {
    // AggregatorV3Interface internal priceFeed;

    constructor() {
        // ETH / USD - Sepolia
        // priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
    }

    function getLatestPrice() public view returns (int256) {
        // (uint80 roundID, int256 price, uint256 startedAt, uint256 timeStamp, uint80 answeredInRound) =
        //     priceFeed.latestRoundData();
        // // for ETH / USD price is scaled up by 10 ** 8
        // return price / 1e8;

        return 3000;
    }
}
