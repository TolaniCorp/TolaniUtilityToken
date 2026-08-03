# Historical Code Archive Notice

Effective August 3, 2026, executable source retained in this repository is classified as historical reference material.

## Status

- Deprecated
- Not canonical
- Not independently audited for current production use
- Not authorized for deployment
- Not authorized for integration
- Not authorized to control live TUT, uTUT, treasury, governance, payment, payroll, escrow, or merchant operations

## Canonical migration target

The approved target repository is `Tolani-Corp/tolani-protocol`.

Until that repository exists and migration acceptance is complete, the currently deployed DAO contracts remain governed from `Tolani-Corp/TolaniEcosystemDAO`.

## Preservation policy

Historical files remain temporarily visible to preserve provenance and permit a controlled migration review. They must be physically removed from the default branch only after:

1. every retained contract has a source repository, source commit, content digest, compiler version, and deployment relationship recorded;
2. the canonical implementation has passed compilation, tests, storage-layout validation, static analysis, and independent review;
3. live contract bytecode and proxy implementation addresses have been reconciled;
4. the migration manifest has been approved;
5. rollback and incident-response procedures are documented.

Repository history remains the authoritative archive after removal from the default branch.
