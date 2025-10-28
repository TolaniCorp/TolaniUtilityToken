# 55_TUT_Utility_Use_Cases.md
**Version:** 1.0  
**Scope:** This document defines **non‑investment** utility for the Tolani Utility Token (**TUT**) across the Tolani Ecosystem DAO. It is written for product, legal, and community teams to align messaging, UX, and on‑chain design.

> **Purpose:** Clearly tie TUT usage to *functional access, coordination, and payments* rather than investment or profit expectations. TUT does **not** represent equity, dividends, or revenue share.

---

## 1) Summary (What TUT *is*)
TUT is the **native utility token** of the Tolani Ecosystem, used for:
- **Governance participation & coordination** (off‑chain voting; on‑chain execution via Safe).
- **Access & permissions** to DAO tools, roles, and gated features.
- **Payments & settlement** for Tolani projects (e.g., HVAC, construction, workforce programs) and internal services.
- **Operational incentives** tied to real‑world activity and ESG programs (not to price or returns).

See tokenomics overview for baseline parameters (symbol/decimals/supply) and the **utility** categories previously defined (payments, payroll, governance, rewards).

---

## 2) Non‑Investment Character (What TUT is *not*)
TUT **is not** a share, note, or promise of profit. The DAO does **not** commit to dividends, buybacks, interest, or revenue sharing. Marketing and UX must avoid investment framing and instead emphasize **utility**, **access**, and **participation**.

**Disallowed** (examples): “invest,” “returns,” “yield,” “price will rise,” “get rich,” “dividends.”  
**Allowed** (examples): “join,” “participate,” “access,” “use,” “pay,” “govern,” “contribute.”

---

## 3) Concrete Use‑Cases (Production)
Below are **approved, non‑investment utilities** with user flows and the on‑chain/UX components that power them.

### 3.1 Governance Participation (Snapshot + Safe execution)
**What users do:** Hold TUT to **participate in proposals** (e.g., Snapshot strategies) and coordinate approved actions executed by a **Gnosis Safe** (treasury & admin).  
**Why this is utility:** It enables decision‑making and coordination; no profit promise.  
**On‑chain/Tools:** Snapshot (off‑chain voting), Safe for multisig execution and role gating; DAO policy in README.

**UX copy (example):** “Join TUT to **participate in proposals** and help steer ecosystem priorities.”

---

### 3.2 Access & Permissions (Role‑based access control)
**What users do:** Holders or designated accounts can **receive roles/permissions** to operate DAO features (e.g., operator roles, minter for test deployments, pauser for emergency ops).  
**Why this is utility:** Token presence or DAO assignment unlocks **functional capability**, not profit.  
**On‑chain/Tools:** `grantRole(bytes32,address)` and `hasRole(bytes32,address)` patterns visible in the admin UI/scripts.

**UX copy (example):** “Acquire TUT to **access member‑only tools** and request DAO roles per policy.”

> Reference: The demo Admin Panel shows role granting via keccak role IDs; the wallet widget demonstrates basic ERC‑20 interactions used in gating flows.

---

### 3.3 Payments for Services (Service credits; internal settlement)
**What users do:** Use TUT to **pay fees** or **settle invoices** for DAO‑provided services (e.g., Tolani HVAC, construction workflows, training).  
**Why this is utility:** TUT acts as a **medium of exchange** within the ecosystem—no promises about price.  
**On‑chain/Tools:** ERC‑20 transfers through standard UIs; internal rate cards & integrations. Ecosystem service scope in README.

**UX copy (example):** “Use TUT to **pay for services** and reduce processing steps across Tolani projects.”

---

### 3.4 Payroll & Work Escrow (Operational usage; no yield)
**What users do:** Contributors can be paid in TUT (or mixed), and **escrow** can hold funds until milestones are met.  
**Why this is utility:** It’s **compensation & workflow settlement**, not an investment program.  
**On‑chain/Tools:** Escrow/payment contracts; internal accounting. The tokenomics/README highlight **payroll & escrow** uses.

**UX copy (example):** “Teams receive TUT for completed milestones; funds release on approval.”

---

### 3.5 ESG Programs & Real‑World Incentives
**What users do:** Projects earn or redeem TUT when they submit verifiable **ESG actions** (e.g., energy efficiency, safe‑work certifications).  
**Why this is utility:** Rewards are tied to **objective actions** and compliance—not investment returns.  
**On‑chain/Tools:** Claim/attestation flows; ESG integration and incentives per ecosystem docs.

**UX copy (example):** “Earn TUT by **completing approved ESG tasks** or certifications.”

---

### 3.6 Training & Workforce Enablement (Tolani Labs)
**What users do:** Learners and staff receive TUT for **course completion**, **skills verification**, or **shift fulfillment**.  
**Why this is utility:** Token usage motivates **participation** and acknowledges **work/output**.  
**On‑chain/Tools:** Payout scripts & role gating; training incentives described in project overview.

**UX copy (example):** “Complete training modules and **unlock TUT‑denominated rewards**.”

---

### 3.7 Fee Reductions & Access Tiers (Holding/Depositing TUT)
**What users do:** Hold or **temporarily deposit** TUT to unlock **reduced platform fees**, **priority support**, or **early access** to features.  
**Why this is utility:** The benefit is a **service feature**, not profit. No commitment to buybacks, yields, or interest.  
**On‑chain/Tools:** Balance checks; role/allowlist mappings; front‑end checks similar to wallet widget.

**UX copy (example):** “Hold TUT to **unlock lower fees** and **priority access** to tools.”

---

## 4) Distribution & Access (Non‑promotional framing)
- **Access paths:** contribute to DAO projects, receive **grants/airdrops** for work, or acquire TUT on permitted venues at user discretion. Avoid “buy now”/FOMO language.
- **No public promises:** The DAO makes **no** promises of price, returns, or future buybacks in connection with distribution.

**Standard disclosure (site/footer):**
> “TUT is a utility token for participation, access, and payments within the Tolani Ecosystem. It is not an investment and does not represent equity or a claim on profits. Use is subject to our Terms & Disclosures.”

---

## 5) Technical Notes (for product/legal)
- **Standard:** ERC‑20 with 18 decimals; front‑end components already read `symbol`, `decimals`, and `balance`.
- **Administrative controls:** Role‑based permissions used for ops (MINTER/PAUSER/UPGRADER). UI & scripts show how roles are granted and checked.
- **Upgradeable architecture:** Upgrade scripts exist; any changes must preserve utility framing and avoid economic rights.

---

## 6) Messaging Guardrails (Do / Don’t)
**Do**
- Say “Join TUT,” “Use TUT to access,” “Pay with TUT,” “Participate in governance.”
- Tie every benefit to a **feature** (governance, access, fees, services).  
- Keep links to docs/tokenomics up to date.

**Don’t**
- Don’t make claims about **price**, **returns**, or **future profits**.
- Don’t use countdown/FOMO tied to speculative purchasing.
- Don’t imply dividends, rev share, or guaranteed yield.

---

## 7) Implementation Checklist (PM/Legal sign‑off)
- [ ] Token utilities in product specs map to **one of the approved categories** above.
- [ ] UX copy uses **join/use/access** verbs; **no investment language**.
- [ ] Terms & Disclosures reviewed by counsel and published.
- [ ] Admin roles owned by the **DAO Safe**; deployer is non‑admin.
- [ ] Airdrop/grants criteria based on **work/actions**, not speculation.
- [ ] Internal reviews documented (PRs, tickets, change logs).

---

## 8) Appendix — References
- Project overview / ecosystem scope (DAO governance, ESG, payroll, training, services).
- Tokenomics summary (symbol/decimals/utility categories).
- Front‑end wallet widget & role admin UI (examples of how access/roles are enforced).
- Scripts for upgrades & role management (technical governance controls).