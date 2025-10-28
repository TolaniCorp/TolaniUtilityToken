# 56_TUT_Decimal_Policy.md
**Standard:** TUT uses ERC‑20 **18 on‑chain decimals** (invariant).  
**Purpose:** Keep UI intuitive while preserving on‑chain precision.

## Display & input conventions
- Governance: 4 dp
- Access & Tiers: 0 dp
- Payments: 2 dp
- Payroll/Escrow: 2 dp
- ESG & Training: 4 dp

**Display rounding:** round down to context precision.  
**Input rounding:** round half‑up to context precision.

**Implementation:** use `tutFormat` / `tutParse` in `src/lib/10_TUT_decimal_policy.js`.  
**Ops invariant:** run `node scripts/deployment/09_assert_decimals_TUT.js` on deploy/upgrade.