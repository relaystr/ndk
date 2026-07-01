---
label: req
title: req
icon: arrow-down-left
order: 1
---

# `req` — query relays for events

Fetches events from one or more relays. Defaults to one JSON object per line;
use `--output summary` for a compact one-line-per-event view.

```
ndk req [options] <relay1> [relay2 ...]
```

| Option | Description |
|--------|-------------|
| `-k`, `--kind <kind>` | Filter by event kind (repeatable) |
| `-a`, `--author <hex\|npub>` | Author pubkey (repeatable) |
| `-i`, `--id <hex\|nevent>` | Event id (repeatable) |
| `-e`, `--e <hex>` | `#e` tag value (repeatable) |
| `-p`, `--p <hex\|npub>` | `#p` tag value (repeatable) |
| `-d`, `--d <value>` | `#d` tag value (repeatable) |
| `-T`, `--hashtag <value>` | `#t` tag value (repeatable) |
| `--tag <k=v>` | Arbitrary single-char tag, e.g. `--tag r=wss://x` (repeatable) |
| `--search <query>` | NIP-50 search |
| `--since <unix\|iso\|dur>` | `created_at >= ` value (`1h`, `2d`, `2024-01-01`, …) |
| `--until <unix\|iso\|dur>` | `created_at <=` value |
| `-l`, `--limit <n>` | Max events to emit (default `10`) |
| `--timeout <sec>` | Query timeout in seconds (default `12`) |
| `-t <sec>` | Alias of `--timeout` (backwards compatible) |
| `-o`, `--output <json\|summary>` | Output mode (default `json`) |
| `--stream` | Live subscription: keep receiving events until Ctrl+C |

Relay URLs may be passed with or without the `wss://` scheme. All filter
flags accept either hex or NIP-19 (`npub`, `nevent`, `note`) forms where it
makes sense.

```bash
# last 5 text notes (kind 1) from a relay
ndk req -k 1 -l 5 wss://relay.damus.net

# kind-0 metadata from two relays, 5s timeout
ndk req -k 0 --timeout 5 relay.damus.net nos.lol

# events by an author (npub accepted), last hour, compact output
ndk req -a npub1... -k 1 --since 1h -l 20 -o summary relay.damus.io

# NIP-50 search
ndk req --search "lightning" -k 1 -l 5 nos.lol

# arbitrary single-char tag, e.g. #r=relay.damus.io
ndk req --tag r=relay.damus.io -k 3 -l 10 relay.damus.io

# live stream of new text notes (Ctrl+C to stop)
ndk req --stream -k 1 relay.damus.io
```
