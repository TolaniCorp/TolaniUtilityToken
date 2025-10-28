# 57_TUT_Gasless_Onboarding.md

**Version:** 1.0  
**Scope:** This document introduces a **gasless onboarding** option for the Tolani Utility Token (**TUT**) ecosystem.  
It explains why gasless transactions are useful, outlines a high‑level implementation using meta‑transactions, and clarifies how this mechanism fits within TUT’s non‑investment utility framework.

---

## 1) Why Gasless Onboarding?

Many newcomers to blockchain are discouraged by the need to pay transaction fees (gas) before they can even acquire or use a token.  
Gasless onboarding enables users to receive and utilize **TUT** without holding ETH or MATIC for gas fees.  
Instead, a **relayer** or **sponsor** pays the gas, allowing frictionless entry into the Tolani ecosystem.  
This aligns with our mission to facilitate **participation, access, and payments** rather than investment or speculation.

**Key benefits:**

- **Lower barrier to entry:** Users can try TUT-powered services without first acquiring a native gas token.
- **Improved UX:** Wallets and apps can abstract away gas from the sign‑up flow, reducing drop‑off.
- **Control & rate limiting:** The DAO can define per‑user limits and conditions to mitigate abuse.

> **Note:** Gasless onboarding is an implementation detail, **not** a change to TUT’s supply or economic rights.  
> TUT remains a utility token with **no profit promise**—see tokenomics and use‑cases docs for context.

---

## 2) How It Works (Overview)

TUT gasless onboarding uses **meta‑transactions**:

1. A user signs a transaction payload off‑chain (e.g., “mint 100 TUT to my address”) using their private key.
2. A **trusted relayer** (operated by the DAO or a partner like Biconomy) receives the signed payload.
3. The relayer submits a transaction to the TUT contract (or a dedicated on‑boarding contract), paying the gas.
4. The contract verifies the user’s signature and, if valid, mints/transfers TUT to the user.

This pattern is typically implemented via **EIP‑2771 (Trusted Forwarders)** or by wrapping calls in a meta‑transaction relay layer.  
Contracts must inherit from `ERC2771Context` or otherwise handle the `msgSender` extraction from the forwarded request.

---

## 3) On‑Chain Considerations

- **Trusted Forwarder:** A single address (or a whitelist) is allowed to relay gasless calls.  
  The DAO governs this forwarder, ensuring it acts responsibly.
- **Nonce Management:** Each user (or meta‑tx signer) must have a nonce to prevent replay attacks.
- **Rate Limits:** The contract can enforce per‑user limits for gasless mints or transfers (e.g., max X TUT per day) to prevent abuse.
- **Fee Sponsorship:** The relayer may be reimbursed in TUT or other arrangements (e.g., periodic compensation from the DAO treasury).
- **Security:** Meta‑transactions must respect the same checks as regular calls (e.g., role gating, supply caps).

---

## 4) Off‑Chain & Frontend Changes

- **Relayer Service:** Deploy or integrate with a relayer that listens for signed payloads and submits them on‑chain.  
  Services like **Biconomy**, **OpenZeppelin Defender**, or a custom Node.js server can fill this role.
- **Frontend UI:** When onboarding, the dApp should:
  1. Prompt the user to sign the onboarding payload (no gas required).  
  2. Send the signature to the relayer via API.  
  3. Display status updates (pending → confirmed) as the relayer submits the transaction.
- **User Education:** Clarify that gasless onboarding is a convenience service.  
  It does not change TUT’s supply or confer any financial rights.

---

## 5) Example Flow

1. **User visits dApp** and clicks “Get TUT (Gasless)”.
2. The app generates a meta‑transaction request (e.g., mint or transfer a small amount of TUT) and asks the user to sign it.
3. The **relayer** receives the signed request via API and submits it to the contract’s `executeMetaTransaction` function, paying gas.
4. The contract verifies the signature, updates nonces, and mints/transfers TUT to the user.
5. The user receives TUT in their wallet without having spent any ETH/MATIC on gas.

---

## 6) Risks & Limitations

- **Relayer Trust:** Users must trust that the designated relayer will not censor or delay their transactions.  
  A multisig‑controlled relayer or multiple relayers mitigate this.
- **Cost:** The DAO must fund gas fees or reimburse the relayer.  
  Clear budgeting and monitoring of gasless onboarding volumes are necessary.
- **Abuse:** Without rate limiting, a single attacker could drain gas funds.  
  Use strict per‑user and per‑period limits and KYC/whitelisting if needed.
- **Complexity:** Implementing EIP‑2771 and relayers adds complexity to smart contracts and front‑end.

---

## 7) Alignment with TUT Tokenomics

Gasless onboarding is an **access mechanism**, not an economic right.  
It does **not** change the total supply, cap, decimals, or distribution described in the tokenomics document.  
It simply allows users to receive or transfer TUT without paying ETH/MATIC gas, funded by the DAO or a sponsor.

Ensure all messaging remains consistent with TUT’s utility framing (access, payments, governance) and avoids investment‑like language.

---

## 8) Next Steps

1. Draft and deploy an upgraded TUT contract (or wrapper) inheriting from `ERC2771Context`.
2. Configure a trusted forwarder address controlled by the DAO’s multisig.
3. Build or integrate a relayer service (e.g., Biconomy) to accept signed onboarding payloads.
4. Update the dApp UI to support the gasless onboarding flow, including signature prompts and status displays.
5. Monitor usage, gas costs, and user feedback; adjust rate limits and funding as needed.

---

**Maintainer Note:** This document complements existing TUT docs such as the tokenomics summary, decimal policy, upgrades guide, and utility use‑cases.  
Any implementation of gasless onboarding must preserve TUT’s non‑investment character and adhere to the DAO’s governance processes.