[README.md](https://github.com/user-attachments/files/23108400/README.md)
# Tolani Utility Token (TUT) 🚀

The Utility Token for participation, access, and payments in the Tolani Ecosystem

---

## 📖 Overview

**TUT** powers DAO governance participation, access & permissions to DAO tools, payments & settlement for Tolani projects (HVAC, construction, workforce programs), payroll/escrow, ESG incentives, and training rewards—**without investment promises**.

- **DAO Governance** (Snapshot voting; Safe execution)
- **Access & Permissions** (role‑based features)
- **Payments & Settlement** (internal services & invoices)
- **Payroll & Escrow** (operational payouts)
- **ESG & Training Incentives** (action‑based rewards)

> TUT is a **utility token**. It is **not** equity or a claim on profits or dividends.

## 🔧 Tech Stack & Tools

| Category       | Tools                                        |
|---------------|----------------------------------------------|
| Blockchain     | Ethereum, Polygon, Arbitrum                  |
| Governance     | Snapshot, Gnosis Safe                        |
| Smart Contracts| Solidity (+ OpenZeppelin), upgradeable proxy |
| Frontend       | React/Next.js                                |
| CI/CD & Testing| Hardhat, GitHub Actions                      |

## 🔢 Decimals & Denomination

- **On‑chain invariant:** `decimals() === 18`.
- **UI policy:** Display/input precision depends on use‑case (Payments/Payroll: 2dp; Governance: 4dp; Access/Tiers: 0dp; ESG/Training: 4dp). See **docs/56_TUT_Decimal_Policy.md**.

## 🚦 Governance & Operations

- Voting on **Snapshot**, execution via **Gnosis Safe**; upgrades follow **validate → prepare → upgrade** with storage layout and decimals checks.
- Roles are assigned to operators by policy (see **docs/ROLES.md**).

## 📑 Documentation

- **55_TUT_Utility_Use_Cases.md** — approved non‑investment utilities
- **56_TUT_Decimal_Policy.md** — display/input precision policy
- **50_Tokenomics (tokenomics.md)** — symbol/decimals/supply
- **UPGRADES.md**, **NETWORKS.md**, **ROLES.md**

## 🛠 Install & Run

```bash
git clone https://github.com/tolanicorp/TolaniToken.git
cd TolaniToken
npm install
npm run dev
```

## 🧪 Compile & Deploy

```bash
npm run contracts:compile
# Configure .env: INIT_ARGS, RPC, etc.
npm run contracts:deploy
```

## 🗂 Networks & Addresses

See `config/addresses.json` and **docs/NETWORKS.md** for the per‑chain proxy/implementation registry.

## 🌐 Domains & ENS Names

We maintain a set of human‑readable ENS domains that map to important addresses in the Tolani ecosystem.  These names make it easy to reference smart contracts, treasuries and DAO portals without copying long hexadecimal addresses.

| Domain               | Purpose                                              |
|---------------------|------------------------------------------------------|
| **tolanicorp.eth**   | Corporate identity and treasury address             |
| **tolanidao.eth**    | Official ENS entry for the Tolani DAO               |
| **tolaniworld.eth**  | Marketing portal and public information gateway    |
| **tolaniecosystemdao.eth** | Primary ENS entry for the Tolani Ecosystem DAO address |
| **tolanitoken.eth**   | Short ENS alias pointing to the TUT token proxy or treasury |
| **tuttoken.dao**      | Unstoppable domain for the TUT token’s web3 presence |
| **tuttoken.eth**      | Alternative ENS name for the TUT token and its treasury |
| **tuttoken.pw**       | Traditional DNS domain used for the TUT token’s public website |

To update or resolve these names:

- Use the [ENS Manager](https://app.ens.domains/) for `.eth` names.  Each ENS domain can point to a contract address, wallet or IPFS content hash.
- Manage `.dao` domains through the Unstoppable Domains dashboard to set crypto addresses or IPFS hashes.
- Configure `.pw` domains through your DNS registrar, setting the appropriate A/AAAA or CNAME records for web hosting or API gateways.

## 🔐 Security

Third‑party audits and continuous review. Report vulnerabilities to <security@tolanicorp.us>.

## 📜 License

MIT

> **Empowering Communities, Building Beyond.**
