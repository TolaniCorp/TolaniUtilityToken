# UPGRADES.md

## Flow (UUPS/Transparent Proxy)

1) Validate the storage layout and prepare the new implementation using:

   ```bash
   node scripts/deployment/02_validate_and_prepare_upgrade_TUTToken.js
   ```

   This script will throw if there is a storage layout incompatibility and will print the address of the prepared implementation.
2) Obtain governance approval (e.g., via Snapshot) and schedule execution via the Gnosis Safe.
3) Execute the upgrade by running:
   ```bash
   node scripts/deployment/03_upgrade_TUTToken.js
   ```
   This will upgrade the proxy to the prepared implementation and log the new implementation address.
4) Record the new proxy and implementation addresses; update `config/addresses.json` and **docs/NETWORKS.md** accordingly.
5) Run the decimals invariant check before and after the upgrade:
   ```bash
   node scripts/deployment/09_assert_decimals_TUT.js
   ```
   The script must report `Decimals invariant OK (18)`.

## Commands

- `node scripts/deployment/03_upgrade_TUTToken.js` — perform the proxy upgrade after validation and governance approval.
- `node scripts/deployment/09_assert_decimals_TUT.js` — ensure the on‑chain decimals remain at 18.

> **Invariant:** `decimals()` must never change from 18.