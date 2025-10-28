# ROLES.md

- `DEFAULT_ADMIN_ROLE` — DAO Safe only.
- `UPGRADER_ROLE` — used during upgrades; scope‑limited.
- `PAUSER_ROLE` — incident response only.
- `MINTER_ROLE` — issuance ops; adhere to cap/vesting policy.

Admin UI and scripts read role constants from the contract and verify `hasRole` before/after.