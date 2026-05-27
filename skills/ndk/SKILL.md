---
name: ndk
description: NDK CLI tool — wallet management (NWC/Cashu) and relay event queries via the `ndk` binary. For library/package development see ndk-core and ndk-flutter skills.
metadata:
  author: relaystr
---

# NDK CLI Tool Skill

Executes the `ndk` binary for wallet operations + relay queries. Supports NWC and Cashu wallets. Local state persists between runs.

> **Scope:** CLI tool only. Library/package development → `ndk-core` skill. Flutter widgets → `ndk-flutter` skill.

## Quick Reference

| Topic | Reference |
|-------|-----------|
| Install binary (Linux/macOS) | [references/installation.md](references/installation.md) |
| All commands overview | [references/commands.md](references/commands.md) |
| Wallets subcommands (add/remove/send/receive/balance/budget) | [references/wallets.md](references/wallets.md) |
| Req command (query Nostr relays) | [references/req.md](references/req.md) |
| Global flags, local DB, edge cases | [references/notes.md](references/notes.md) |

## One-Line Summary

```
wallets add nwc|cashu → wallets list → wallets balance → wallets send|receive
```
