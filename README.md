# Tolani Utility Token (TUT)

> **Documentation-only public repository.** This repository is not an authoritative source for deployable smart contracts, ABIs, deployment scripts, relayers, wallets, payment services, or production configuration.

TUT is the Tolani ecosystem utility and governance token. Its approved utility scope includes governance coordination, controlled access, service settlement, workforce programs, verified training rewards, and ecosystem participation. TUT is not equity, a dividend, a revenue share, or a claim on Tolani Corp profits.

## Canonical source policy

The target canonical engineering repository is:

- `Tolani-Corp/tolani-protocol`

Until that repository is created and its migration is independently validated, the operational source for the currently deployed DAO stack remains:

- `Tolani-Corp/TolaniEcosystemDAO`

Historical code retained in this repository is **deprecated, unaudited for current production use, and non-deployable by policy**. Do not compile, deploy, fork, or integrate against it.

## Current production deployment registry

Primary networks:

- Ethereum mainnet: canonical TUT origin
- Base mainnet: primary governance, utility, rewards, and payment-development network

Known canonical addresses pending automated chain reconciliation:

| Component | Network | Address |
| --- | --- | --- |
| TUT proxy | Ethereum | `0x90e9d7189D605a824C2481Fe88A1d9A7DDFAF71D` |
| Bridged TUT | Base | `0xAf7e938741a720508897Bf3a13538f6713A337A4` |
| uTUT | Base | `0x6D3205ba4066260ca4B94F9221c46b95B1eedcD4` |
| Governor | Base | `0xeEd65936FaEDb315c598F8b1aF796289BCE2B7f6` |
| Timelock | Base | `0xb23f0662511ec0ee8d3760e3158a5Ab01551d52d` |
| Treasury | Base | `0x3FaB09377944144eB991DB2a5ADf2C96A5e8587c` |
| TUT converter | Base | `0xF064C89198Ce3c595bf60ac0b6A12045CB49ebeD` |
| Training rewards | Base | `0x24D8bE6650DBb2e4F15FcCE540b1f417A48B3526` |
| Staking pool | Base | `0xA2887e45E0aFF0476a841c3eE4a647A21f32A628` |

These entries are informational. Production integrations must use a generated, signed deployment registry backed by direct chain reads.

## Repository rules

This repository accepts documentation changes only. The following are prohibited:

- smart-contract development or deployment;
- private keys, RPC secrets, wallet files, or signing material;
- executable payment, relayer, custody, or transfer services;
- manually asserted production addresses without evidence;
- investment, profit, appreciation, or passive-return claims.

See:

- `ARCHIVE_NOTICE.md`
- `docs/STATUS.md`
- `docs/CONTRACTS.md`
- `SECURITY.md`
- `CONTRIBUTING.md`

## Security

Do not disclose vulnerabilities in public issues. Report security concerns to `security@tolanicorp.us`.

## License

Documentation and retained historical source remain subject to the repository license. No retained code should be interpreted as production authorization.
