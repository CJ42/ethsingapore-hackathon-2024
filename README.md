# AlphaHook - ETHGlobal Singapore 2024

![logo](./docs/header.png)

A project by [@CJ42](https://github.com/CJ42) and [@Hugoo](https://github.com/Hugoo) for [ETHGlobal Singapore 2024](https://ethglobal.com/events/singapore2024) hackathon.

This repo is based on [@uniswapfoundation/v4-template](https://github.com/uniswapfoundation/v4-template).

[Project showcase on ETHGlobal website](https://ethglobal.com/showcase/alphahook-rqd6q).

## Description

### Uniswap V3

In [Uniswap V3](https://docs.uniswap.org/contracts/v3/overview), fees are fixed within each specific pool. As a result, for certain trades, the router may need to execute swaps across multiple pools. The fee structure is closely related to the price volatility of a trading pair. For stable pairs, such as USDC/USDT, low-fee pools are typically favored. Conversely, for high-volatility pairs, liquidity providers tend to prefer pools with higher fees to better compensate for the risks involved.

```mermaid
graph LR
    A[🧑‍💻 Trader] --> B[🔀 Router]
    B --> C
    B --> D
    B --> E
    B --> F
    subgraph Pool V3 A/B
    C[0.01% Fees]
    D[0.05% Fees]
    E[0.30% Fees]
    F[1.00% Fees]
    end
```

One challenge with this architecture is that liquidity can become "trapped" in a pool where the fees no longer align with the volatility of the pair. For example, a pair involving two newly launched tokens may experience significant price volatility, making high fees desirable. However, as the price stabilizes over time, lower fees would become more appropriate. Currently, adjusting fees requires liquidity providers to withdraw from one pool and reallocate to another. With Uniswap V4 hooks, this process can be automated, enabling dynamic fee adjustments without requiring manual intervention from liquidity providers.

### Uniswap V4

In [Uniswap V4](https://docs.uniswap.org/contracts/v4/overview), we can leverage hooks to adjust the fees automatically. In this project, we show a way to adjust the pool fees dynamically, by using external data from Chainlink oracles.

```mermaid
graph LR
    A[🧑‍💻 Trader] --> B[🔀 Router]
    B --> C
    subgraph Pool V4 A/B
    C[Dynamic Fees]
    end
    C <--> D([🔮 Oracle])
```

## Implementation

### Swap Hooks

Our application leverages hooks before and swap have occurred, with some custom Solidity logic.

The goal was to explore hooks for the following use cases:

- Dynamic Fees - showcase potential hooks that rely on dynamic fees to reward LPs or swappers
- Hook Fees - showcase novel hook fee designs

The `PoolManager` uses permissions to determine which hook functions to call for a given pool on a Hook contract.

Since we used the Uniswap v4 hooks only for operations related to swapping, we specified only the permissions for the `beforeSwap` and `afterSwap` in the hook contract.

```solidity
function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
    return Hooks.Permissions({
        beforeInitialize: false,
        afterInitialize: false,
        beforeAddLiquidity: false,
        afterAddLiquidity: false,
        beforeRemoveLiquidity: false,
        afterRemoveLiquidity: false,
        beforeSwap: true,
        afterSwap: true,
        beforeDonate: false,
        afterDonate: false,
        beforeSwapReturnDelta: false,
        afterSwapReturnDelta: false,
        afterAddLiquidityReturnDelta: false,
        afterRemoveLiquidityReturnDelta: false
    });
}
```

### Formula for weighted average volatility

The example from the docs of Uniswap V4 implement dynamic fee adjustments automatically at the time of the swap. 

Alpha Hook implementation enhances Uniswap's volatility-based fee system using a **weighted average of volatility** 

Instead of reacting to short-term price spikes (which can make swap fee rise considerably at on these short time periods), The Alpha Hook contract calculates a weighted average of volatility over over 3 different time frame (24 hours, 7 days and 30 days) to smooth fee adjustments. This reduces drastic fee fluctuations and protects liquidity providers from short-lived volatility.

To calculate the **weighted average of volatility based on time**, we used the following formula that assigns different weights to volatility measurements over various time frames:

![Math Formula for weighted average volatility](./weighted-volatility-formula.png)

> **Note:** this method gives more emphasis to _short-term volatility_ but still considers longer-term trends to smooth out the volatility measure. 
> The weights could be adjusted according to how sensitive you want the fee system to be to different time frames. For instance one could put more weight on the 30 days time frame to make the fee more sensitive to the long term volatility (_e.g: 50 % instead of 20% in the current implementation_).


### Tech stack

- [Uniswap V4](https://docs.uniswap.org/contracts/v4/overview)
- [Chainlink](https://chain.link/)
- [Next.js](https://nextjs.org/)
- [Foundry](https://book.getfoundry.sh/)

## Next steps

If the hook contract exposes relevant variables and function, a frontend can nicely display the information to the user.

## Resources

We have explored the following documentation pages to develop our submission:

- **To learn how Uniswap v4 hooks work:** https://docs.uniswap.org/contracts/v4/concepts/hooks
- **To learn how to build custom hooks for swaps:** https://docs.uniswap.org/contracts/v4/guides/hooks/swap
- **To calculate percentages in the weighted time average volatility formula:** https://muens.io/solidity-percentages
- **To learn more about Chainlink data feeds:** https://docs.chain.link/data-feeds/rates-feeds#realized-volatility

## Feedback

- The [template repo](https://github.com/uniswapfoundation/v4-template) is just amazing and a very great place to start 👏.
- When searching "Uniswap V4" on Google, the first link to <https://docs.uniswap.org/contracts/v4/concepts/intro-to-v4> is a broken link. Maybe a redirect can be added to fix this.
