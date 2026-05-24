---
name: ndk
description: Nostr Development Kit CLI — wallet management (NWC/Cashu) and relay event queries over the Nostr network.
license: MIT
metadata:
  author: relaystr
  version: "0.8.4"
---

# NDK CLI Skill

Nostr wallet operations + relay queries. Supports NWC and Cashu wallets. Local state persists between runs.

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
