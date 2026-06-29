---
label: broadcast
title: broadcast
icon: arrow-up-right
order: 2
---

# `broadcast` — publish events to relays

Publishes one event to the given relays and prints a per-relay result
(`OK`, `REJECTED`, or `NO-RESPONSE`). Accepts three kinds of input:

1. **Pre-signed event JSON** — sent as-is (no signer needed).
2. **Unsigned event JSON** or **inline build** (`--kind` + `--content`) —
   signed with `--privkey` or the active `accounts login` identity.
3. **Build a text note inline** — `--kind 1 --content "..."` plus a signer.

```
ndk broadcast [options] <relay> [relay ...]
```

Event source (exactly one required):

| Option | Description |
|--------|-------------|
| `--event <json>` | Inline event JSON |
| `--file <path>` | Read event JSON from file |
| `--stdin` | Read event JSON from stdin (pipe or interactive) |
| `--kind <int>` + `--content <text>` | Build an unsigned text note inline |
| `--pubkey <hex\|npub>` | Pubkey for inline build (defaults to active account) |

Signing:

| Option | Description |
|--------|-------------|
| `--privkey <hex\|nsec>` | Sign with this key (overrides the active account) |
| *(none)* | Use the active account from `ndk accounts login` |

Output control:

| Option | Description |
|--------|-------------|
| `--relay <url>` | Target relay (repeatable; also accepted positionally) |
| `--timeout <sec>` | Per-event broadcast timeout (default `10`) |
| `--consider-done <0..1>` | Fraction of OKs to wait for (default `0.5`) |
| `--no-cache` | Don't save event to local cache |

```bash
# publish a text note using the active account
ndk accounts login nsec nsec1...    # one-time
ndk broadcast --kind 1 --content "hello from ndk cli" relay.damus.io nos.lol

# publish a text note with an explicit private key
ndk broadcast --kind 1 --content "hello" --privkey nsec1... relay.damus.io

# broadcast a pre-signed event from a file
ndk broadcast --file signed.json relay.damus.io

# broadcast a pre-signed event piped on stdin
cat signed.json | ndk broadcast --stdin relay.damus.io

# custom OK threshold and timeout
ndk broadcast --event '{...}' --consider-done 1.0 --timeout 20 \
    relay.damus.io nos.lol relay.nostr.band
```

Exit code is `0` if at least one relay accepted the event, `1` otherwise.
