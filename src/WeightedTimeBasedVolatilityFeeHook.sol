// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// interfaces
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {IVolatilityOracle} from "./IVolatilityOracle.sol";
import {LPFeeLibrary} from "v4-core/src/libraries/LPFeeLibrary.sol";

// modules
import {BaseHook} from "v4-periphery/src/base/hooks/BaseHook.sol";

// libraries
import {Hooks, IHooks} from "v4-core/src/libraries/Hooks.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {FullMath} from "v4-core/src/libraries/FullMath.sol";

// constants
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {BalanceDelta} from "v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "v4-core/src/types/BeforeSwapDelta.sol";

// Errors
import "./Errors.sol" as Errors;

/// @title Hook contract for dynamic adjusted fees based volatility (weighted average)
/// @author Jean Cavallera <CJ42>, Hugo Masclet <Hugoo>
contract WeightedTimeBasedVolatilityFeeHook is BaseHook {
    using PoolIdLibrary for PoolKey;

    // Basis points to calculate percentages for the weighted average (1 % = 100 bps)
    // See: https://muens.io/solidity-percentages
    uint256 internal constant _BASIS_POINTS_BASE = 1_000_000; // 100 %

    // Volatility thresholds
    uint256 public constant HIGH_VOLATILITY_TRIGGER = 140_000; // 14%
    uint256 public constant MEDIUM_VOLATILITY_TRIGGER = 100_000; // 10%
    uint256 public constant LOW_VOLATILITY_TRIGGER = 60_000; // 6%

    // Volatility fee tiers
    uint24 public constant HIGH_VOLATILITY_FEE = 10_000; // 1%
    uint24 public constant MEDIUM_VOLATILITY_FEE = 3_000; // 0.3%
    uint24 public constant LOW_VOLATILITY_FEE = 500; // 0.05%

    /// @dev Oracle used to retrieve the current volatility of the pair
    IVolatilityOracle public immutable VOLATILITY_ORACLE;

    /// @dev Time interval that fees are re-calculated based on the latest volatility figures
    uint256 public immutable FEE_UPDATE_INTERVAL;

    /// @dev Timestamp at which the fee were last updated
    uint256 public lastFeeUpdate;

    constructor(IPoolManager _poolManager, IVolatilityOracle _volatilityOracle, uint256 _feeInterval)
        BaseHook(_poolManager)
    {
        if (_feeInterval < 1 minutes) {
            revert Errors.FeeIntervalTooSmall(_feeInterval);
        }

        if (_feeInterval > 1 hours) {
            revert Errors.FeeIntervalTooLarge(_feeInterval);
        }

        VOLATILITY_ORACLE = _volatilityOracle;
        FEE_UPDATE_INTERVAL = _feeInterval;
    }

    /// @dev Setup permissions to run hooks only for swaps
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

    /// @inheritdoc IHooks
    function afterInitialize(
        address, /* sender */
        PoolKey calldata key,
        uint160, /* sqrtPriceX96 */
        int24, /* tick */
        bytes calldata /* hookData */
    ) external override returns (bytes4) {
        uint24 initialFee = getSwapFeeBasedOnWeightedVolatility();
        poolManager.updateDynamicLPFee(key, initialFee);
        return IHooks.afterInitialize.selector;
    }

    /// @dev Reduce drastic fee fluctations (for instance, when fee increase during short-term price spikes)
    /// using a weighted averages of volatility over different time frames (= 1 minute, 1 hour and 1 day).
    ///
    /// This hook function calculates this weighted average of volatility and adjust the fees accordingly.
    /// This protects liquidity providers from short-lived volatility, and offer "smooth fee adjustments" 🥤
    function beforeSwap(
        address, /* sender */
        PoolKey calldata, /* key */
        IPoolManager.SwapParams calldata, /* swapParams */
        BalanceDelta,
        bytes calldata /* hookData */
    ) external virtual onlyPoolManager returns (bytes4, BeforeSwapDelta, int128) {
        if (block.timestamp >= lastFeeUpdate + FEE_UPDATE_INTERVAL) {
            uint24 newFee = getSwapFeeBasedOnWeightedVolatility();
            lastFeeUpdate = block.timestamp;

            int128 overridenLpFee = int128(uint128(newFee | LPFeeLibrary.OVERRIDE_FEE_FLAG));

            return (IHooks.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, overridenLpFee);
        }
        return (IHooks.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }

    /// dev Calculate the fee for the swap based on the volatility of the market.
    /// The volatility is based on a time average formula, not on the volatility at the time the swap is made
    /// This helps smoothen the swap fee paid overall, and reduce the risk of paying high fees when volatility surge in short time periods.
    /// See function `calculateWeightedTimeVolatility(...)` for more details
    function getSwapFeeBasedOnWeightedVolatility() public view returns (uint24) {
        (int256 volatilityMinute, int256 volatilityHour, int256 volatilityDay) = _getVolatilityMetrics();

        uint256 currentWeightedVolatility =
            _calculateWeightedTimeVolatility(volatilityMinute, volatilityHour, volatilityDay);

        if (currentWeightedVolatility >= HIGH_VOLATILITY_TRIGGER) {
            return HIGH_VOLATILITY_FEE;
        } else if (
            currentWeightedVolatility > MEDIUM_VOLATILITY_TRIGGER && currentWeightedVolatility < HIGH_VOLATILITY_TRIGGER
        ) {
            return MEDIUM_VOLATILITY_FEE;
        } else {
            return LOW_VOLATILITY_FEE;
        }
    }

    /// @dev Query oracle for various volatility metrics on ETH - USD market
    /// For more details, see Chainlink oracle docs:
    /// - https://docs.chain.link/data-feeds/rates-feeds#realized-volatility
    /// - https://docs.chain.link/data-feeds/rates-feeds/addresses?network=ethereum&page=1
    function _getVolatilityMetrics() internal view returns (int256, int256, int256) {
        return (
            VOLATILITY_ORACLE.realizedVolatility24Hours(),
            VOLATILITY_ORACLE.realizedVolatility7Days(),
            VOLATILITY_ORACLE.realizedVolatility30Days()
        );
    }

    /// @dev Calculate weighted average volatility based on different time frames.
    // The volatility is weighted more heavily toward the short term (1-minute)
    // but also takes into account longer time frames to prevent overreaction to price spikes.
    function _calculateWeightedTimeVolatility(int256 volatilityMinute, int256 volatilityHour, int256 volatilityDay)
        internal
        pure
        returns (uint256)
    {
        // 50%
        uint256 weightedVolatilityMinute =
        // TODO: How to implement percentages on signed integers `intN`?
         FullMath.mulDiv({a: uint256(volatilityMinute), b: 5_000, denominator: _BASIS_POINTS_BASE});

        // 30%
        uint256 weightedVolatilityHour =
            FullMath.mulDiv({a: uint256(volatilityHour), b: 3_000, denominator: _BASIS_POINTS_BASE});

        // 20%
        uint256 weightedVolatilityDay =
            FullMath.mulDiv({a: uint256(volatilityDay), b: 2_000, denominator: _BASIS_POINTS_BASE});

        return weightedVolatilityMinute + weightedVolatilityHour + weightedVolatilityDay;
    }
}
