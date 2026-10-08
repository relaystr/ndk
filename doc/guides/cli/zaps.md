---
label: zaps
title: zaps
icon: zap
order: 5
---

# `zaps` — NIP-57 zap operations

Send and inspect Lightning zaps. The `zap` sub-command pays from a stored NWC
wallet (see [`wallets add nwc`](wallets.md)); `invoice` only fetches a BOLT11
invoice and needs no wallet; `receipts` reads kind `9735` zap receipts.

```
ndk zaps <sub-command> [args]
```

| Sub-command | Description |
|-------------|-------------|
| `invoice <lud16> <amountSats>` | Fetch a zap/lightning invoice (no payment). Zap-encoded when a signer and recipient `--pubkey` are available; `--no-zap` forces a plain LN invoice. |
| `zap <lud16> <amountSats>` | Pay a zap using the default NWC sending wallet (or `--wallet <id>`). Waits for the zap receipt unless `--no-receipt`. |
| `receipts <pubkey>` | List kind `9735` zap receipts for a recipient (filter with `--event` / `--addressable`). |

## Options

| Option | Description |
|--------|-------------|
| `--wallet <walletId>` | Override the NWC wallet used by `zap` |
| `--comment <text>` | Zap comment / invoice memo |
| `--pubkey <hex\|npub>` | Recipient pubkey (enables true zap encoding) |
| `--event <id\|nevent>` | Zap a specific event |
| `--addressable <aTag>` | Zap an addressable event (`naddr`) |
| `--relays <url>` (repeatable) | Relays attached to the zap request |
| `--no-zap` | `invoice`: force a plain LN invoice (skip zap encoding) |
| `--no-receipt` | `zap`: don't wait for the zap receipt |
| `--limit <n>` | `receipts`: max events (default `50`) |
| `--timeout <sec>` | Per-operation timeout (default `15`) |

## Examples

```bash
# fetch a 21-sat zap invoice for a lud16 address
ndk zaps invoice me@example.com 21

# zap 1000 sats from the default NWC sending wallet,
# encoding a true zap with the active account as sender
ndk accounts login nsec nsec1...        # one-time
ndk wallets add nwc "nostr+walletconnect://..."
ndk zaps zap me@example.com 1000 --pubkey npub1...

# list zap receipts received by a pubkey (last hour)
ndk zaps receipts npub1... --limit 50

# zap a specific note
ndk zaps zap me@example.com 21 --pubkey npub1... --event nevent1...
```
