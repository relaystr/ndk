---
name: ndk-flutter
description: Flutter UI package for Nostr apps — ready-to-use widgets, account/login management, and wallet UI built on top of the ndk Dart library.
metadata:
  author: relaystr
---

# NDK Flutter Skill

Flutter widgets + account/session management for Nostr apps. Built on `ndk` package. Not a binary — this is library/UI development guidance.

> **Scope:** Flutter package (`ndk_flutter`) development and usage. CLI tool → `ndk` skill. Core Dart lib → `ndk-core` skill.

## Quick Reference

| Topic | Reference |
|-------|-----------|
| Setup (pub add, l10n, NdkFlutter init) | [references/setup.md](references/setup.md) |
| All widgets (NBanner, NLogin, NWallets…) | [references/widgets.md](references/widgets.md) |
| Account state (save/restore, signers) | [references/accounts.md](references/accounts.md) |

## One-Line Summary

```
flutter pub add ndk ndk_flutter → wrap with NdkFlutter → use N* widgets
```
