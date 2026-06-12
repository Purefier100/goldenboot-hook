# ⚽ GoldenBoot Hook

> A Uniswap V4 Hook on X Layer that dynamically adjusts swap fees based on live World Cup 2026 match results.

Built for the **X Layer Build X Hackathon** — World Cup Edition.

---

## How It Works

GoldenBoot Hook connects the beautiful game to DeFi. Every liquidity pool is linked to a World Cup team. When that team plays, the swap fees change in real time based on the match outcome:

| Match State | Fee | Why |
|---|---|---|
| Before match / Pending | 0.30% | Standard trading |
| 🏆 Team Wins | 0.05% | Celebrate with ultra-cheap swaps |
| 💀 Team Loses | 1.00% | Premium fee on defeat |

This creates a completely new DeFi primitive — **emotion-driven liquidity**. Fans of a winning team rush to swap at 0.05%, driving massive volume. The hook captures that energy on-chain.

---

## Architecture

```
Owner (oracle updater)
    │
    ├── setMatchResult(teamId, Win/Loss/Pending)
    │       Updates match result for a team
    │
    └── setPoolTeam(poolId, teamId)
            Links a Uniswap V4 pool to a World Cup team

User Swap
    │
    └── beforeSwap() fires
            └── reads poolTeam[poolId] → matchResults[teamId]
                    └── returns dynamic fee with OVERRIDE_FEE_FLAG
```

### Fee Logic (`beforeSwap`)
```solidity
// Win  → 0.05% (FEE_WIN    = 500)
// Loss → 1.00% (FEE_LOSS   = 10000)
// Default → 0.30% (FEE_DEFAULT = 3000)
uint24 fee = _currentFee(key) | LPFeeLibrary.OVERRIDE_FEE_FLAG;
```

---

## Contracts

| Contract | Description |
|---|---|
| `src/GoldenBootHook.sol` | Main hook — dynamic fee logic |
| `test/GoldenBootHook.t.sol` | 11 passing unit tests |

---

## Deployment

**Network:** X Layer Mainnet  
**Chain ID:** 196  
**Gas Token:** OKB  
**RPC:** https://rpc.xlayer.tech  
**Explorer:** https://www.oklink.com/xlayer

```bash
# Deploy
forge script script/Deploy.s.sol \
  --rpc-url xlayer \
  --broadcast \
  --verify

# Set a match result (owner only)
cast send <HOOK_ADDRESS> \
  "setMatchResult(bytes32,uint8)" \
  $(cast keccak "Brazil") 1 \
  --rpc-url xlayer
```

---

## Local Development

```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash && foundryup

# Clone & install
git clone https://github.com/Purefier100/goldenboot-hook
cd goldenboot-hook
forge install

# Build
forge build

# Test
forge test -vvv
```

---

## Tests

```
forge test -vvv
```

All 11 tests pass:
- ✅ Owner is deployer
- ✅ Non-owner cannot set match result
- ✅ Non-owner cannot set pool team
- ✅ Default fee when no team set (3000)
- ✅ Win fee when team wins (500)
- ✅ Loss fee when team loses (10000)
- ✅ Default fee when result is pending
- ✅ Override flag is set on fee
- ✅ MatchResultUpdated event emits
- ✅ PoolTeamSet event emits
- ✅ All hook selectors return correctly

---

## World Cup Teams Supported

Any team can be tracked by passing its `keccak256` hash as `teamId`:

```solidity
bytes32 brazil   = keccak256("Brazil");
bytes32 england  = keccak256("England");
bytes32 france   = keccak256("France");
bytes32 germany  = keccak256("Germany");
bytes32 spain    = keccak256("Spain");
```

---

## Hackathon Submission

- **Event:** X Layer Build X Hackathon
- **Chain:** X Layer (Chain ID 196)
- **Wallet:** Trade via OKX Wallet on Uniswap V4 to count toward volume
- **X Account:** [@GoldenBootHook](https://twitter.com/GoldenBootHook)

---

## License

MIT
