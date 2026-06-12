// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IHooks} from "v4-core/src/interfaces/IHooks.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {BalanceDelta} from "v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "v4-core/src/types/BeforeSwapDelta.sol";
import {LPFeeLibrary} from "v4-core/src/libraries/LPFeeLibrary.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";

/// @title GoldenBootHook
/// @notice Uniswap V4 hook that dynamically adjusts swap fees based on World Cup match results.
/// - Default (before match): 0.30% fee (3000)
/// - Tracked team wins:      0.05% fee (500)   — celebrate with cheap swaps
/// - Tracked team loses:     1.00% fee (10000) — premium on defeat
contract GoldenBootHook is IHooks {
    using LPFeeLibrary for uint24;

    // Fee tiers in hundredths of a bip (1e6 = 100%)
    uint24 public constant FEE_DEFAULT = 3000;   // 0.30%
    uint24 public constant FEE_WIN    = 500;     // 0.05%
    uint24 public constant FEE_LOSS   = 10000;   // 1.00%

    enum MatchResult {
        Pending,
        Win,
        Loss
    }

    IPoolManager public immutable poolManager;
    address public owner;

    // teamId => current result
    mapping(bytes32 => MatchResult) public matchResults;

    // poolId => teamId being tracked for this pool
    mapping(bytes32 => bytes32) public poolTeam;

    event MatchResultUpdated(bytes32 indexed teamId, MatchResult result);
    event PoolTeamSet(bytes32 indexed poolId, bytes32 indexed teamId);

    error NotOwner();
    error NotPoolManager();

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier onlyPoolManager() {
        if (msg.sender != address(poolManager)) revert NotPoolManager();
        _;
    }

    constructor(IPoolManager _poolManager) {
        poolManager = _poolManager;
        owner = msg.sender;
    }

    /// @notice Report a match result for a team.
    function setMatchResult(bytes32 teamId, MatchResult result) external onlyOwner {
        matchResults[teamId] = result;
        emit MatchResultUpdated(teamId, result);
    }

    /// @notice Associate a pool with a team to track.
    function setPoolTeam(bytes32 poolId, bytes32 teamId) external onlyOwner {
        poolTeam[poolId] = teamId;
        emit PoolTeamSet(poolId, teamId);
    }

    function _currentFee(PoolKey calldata key) internal view returns (uint24) {
        bytes32 pid = keccak256(abi.encode(key));
        bytes32 tid = poolTeam[pid];
        if (tid == bytes32(0)) return FEE_DEFAULT;

        MatchResult r = matchResults[tid];
        if (r == MatchResult.Win)  return FEE_WIN;
        if (r == MatchResult.Loss) return FEE_LOSS;
        return FEE_DEFAULT;
    }

    function beforeInitialize(address, PoolKey calldata, uint160) external pure override returns (bytes4) {
        return IHooks.beforeInitialize.selector;
    }

    function afterInitialize(address, PoolKey calldata, uint160, int24) external pure override returns (bytes4) {
        return IHooks.afterInitialize.selector;
    }

    function beforeAddLiquidity(address, PoolKey calldata, IPoolManager.ModifyLiquidityParams calldata, bytes calldata)
        external pure override returns (bytes4)
    {
        return IHooks.beforeAddLiquidity.selector;
    }

    function afterAddLiquidity(
        address, PoolKey calldata, IPoolManager.ModifyLiquidityParams calldata,
        BalanceDelta, BalanceDelta, bytes calldata
    ) external pure override returns (bytes4, BalanceDelta) {
        return (IHooks.afterAddLiquidity.selector, BalanceDelta.wrap(0));
    }

    function beforeRemoveLiquidity(
        address, PoolKey calldata, IPoolManager.ModifyLiquidityParams calldata, bytes calldata
    ) external pure override returns (bytes4) {
        return IHooks.beforeRemoveLiquidity.selector;
    }

    function afterRemoveLiquidity(
        address, PoolKey calldata, IPoolManager.ModifyLiquidityParams calldata,
        BalanceDelta, BalanceDelta, bytes calldata
    ) external pure override returns (bytes4, BalanceDelta) {
        return (IHooks.afterRemoveLiquidity.selector, BalanceDelta.wrap(0));
    }

    /// @notice Override the LP fee dynamically based on match result.
    function beforeSwap(address, PoolKey calldata key, IPoolManager.SwapParams calldata, bytes calldata)
        external view override returns (bytes4, BeforeSwapDelta, uint24)
    {
        uint24 fee = _currentFee(key) | LPFeeLibrary.OVERRIDE_FEE_FLAG;
        return (IHooks.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, fee);
    }

    function afterSwap(address, PoolKey calldata, IPoolManager.SwapParams calldata, BalanceDelta, bytes calldata)
        external pure override returns (bytes4, int128)
    {
        return (IHooks.afterSwap.selector, 0);
    }

    function beforeDonate(address, PoolKey calldata, uint256, uint256, bytes calldata)
        external pure override returns (bytes4)
    {
        return IHooks.beforeDonate.selector;
    }

    function afterDonate(address, PoolKey calldata, uint256, uint256, bytes calldata)
        external pure override returns (bytes4)
    {
        return IHooks.afterDonate.selector;
    }
}
