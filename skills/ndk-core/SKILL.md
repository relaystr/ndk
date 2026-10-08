---
name: ndk-core
description: NDK Dart library — Nostr Development Kit core package. Event requests, relay management, accounts, wallets (NWC/Cashu), zaps, files (Blossom), and more.
metadata:
  author: relaystr
---

# NDK Core Library Skill

Core Dart library for building Nostr apps. Not a binary — this is library development guidance.

> **Scope:** `ndk` Dart package (`packages/ndk`). CLI tool → `ndk` skill. Flutter widgets → `ndk-flutter` skill.

## Quick Reference

| Topic | Reference |
|-------|-----------|
| Setup + Ndk init (NdkConfig, engines, cache) | [references/setup.md](references/setup.md) |
| Requests + subscriptions (query relays) | [references/requests.md](references/requests.md) |
| Accounts + signers | [references/accounts.md](references/accounts.md) |
| Usecases overview (all ndk.* accessors) | [references/usecases.md](references/usecases.md) |
| Wallets (NWC + Cashu) | [references/wallets.md](references/wallets.md) |

## One-Line Summary

```
NdkConfig(cache, eventVerifier) → Ndk(config) → ndk.requests / ndk.accounts / ndk.wallets / …
```
