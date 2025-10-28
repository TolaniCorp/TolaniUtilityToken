# TolaniToken Contribution Guidelines

Thanks for contributing to the Tolani Utility Token (**TUT**) project.

## PR Requirements (must pass)

- ✅ **Decimals invariant:** run `node scripts/deployment/09_assert_decimals_TUT.js` against the target proxy; it must report `18`.
- ✅ **UI amounts:** any component that displays or collects TUT amounts must use `tutFormat`/`tutParse` from `src/lib/10_TUT_decimal_policy.js` with the correct **context** (payments, governance, access, etc.).
- ✅ Tests & lint pass; commits are descriptive.

## Getting Started

1. Fork & clone this repository.
2. Run `npm install` to install dependencies.
3. Create a feature branch off of `main`.
4. Run tests locally with `npm test` and lint with `npm run lint`.
5. Open a PR with a clear description when ready.

## Code Standards

- Use the Solidity style guide for smart contracts.
- JavaScript/TypeScript should be formatted with Prettier.
- Upgrade PRs must include storage layout notes and `validateUpgrade` logs.

## Security

If you discover a vulnerability, **do not** open a public issue. Email <security@tolanicorp.us>.

> This repo enforces **utility‑only messaging** (no investment framing).