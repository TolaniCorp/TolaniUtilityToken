# Contract and Network Reference

This document is a public reference only. Production systems must consume a signed deployment registry generated from direct chain reads.

## Ethereum mainnet

| Component | Address | Status |
| --- | --- | --- |
| TUT proxy | `0x90e9d7189D605a824C2481Fe88A1d9A7DDFAF71D` | Token origin |
| TUT implementation | `0x66CF392d1627404311Ee126292C4c949BCCb3025` | Recorded implementation; reconcile before use |

## Base mainnet

| Component | Address | Status |
| --- | --- | --- |
| Bridged TUT | `0xAf7e938741a720508897Bf3a13538f6713A337A4` | Primary L2 token |
| uTUT | `0x6D3205ba4066260ca4B94F9221c46b95B1eedcD4` | Existing reward token; replacement design required |
| Governor | `0xeEd65936FaEDb315c598F8b1aF796289BCE2B7f6` | Deployed |
| Timelock | `0xb23f0662511ec0ee8d3760e3158a5Ab01551d52d` | Deployed |
| Treasury | `0x3FaB09377944144eB991DB2a5ADf2C96A5e8587c` | Deployed and funded |
| Session key registry | `0x73e8fDfE1EEd5f6fbE47Ef9bCEaD76da78516025` | Deployed |
| TUT converter | `0xF064C89198Ce3c595bf60ac0b6A12045CB49ebeD` | Reserve funded |
| Training rewards | `0x24D8bE6650DBb2e4F15FcCE540b1f417A48B3526` | Deployed |
| Clean staking pool | `0xA2887e45E0aFF0476a841c3eE4a647A21f32A628` | Unfunded and inactive |
| DAO Safe | `0x57dd8B744fd527c4cbd983d2878a29c5116ab855` | Recorded administrative multisig |

## Payment-rail warning

The currently referenced Base MerchantRegistry and PaymentProcessor are:

- MerchantRegistry: `0xE9A1Dd9f175c28C954F961A5eec07D116F1359F3`
- PaymentProcessor: `0x51E2c780A513b9C9A76344d376711f603294a2f7`

Historical deployment records indicate that this processor may be constructor-bound to different TUT and uTUT addresses than the current canonical Base assets. Production POS use is blocked until direct RPC reads reconcile its token, registry, fee-collector, role, pause, and payment-count state.

## Evidence requirements

Every address change must include:

1. chain ID;
2. transaction hash;
3. deployed bytecode hash;
4. verified source and compiler settings;
5. proxy implementation and admin where applicable;
6. role-holder inventory;
7. source repository and commit;
8. reviewer and approval timestamp.
