---
title: CLI
icon: terminal
order: 99.5
---

# NDK CLI

NDK ships a standalone command line interface for querying relays and managing wallets, without writing any Dart code. It is a prebuilt binary — no Dart or Flutter toolchain required.

## Install

### Single command (Linux / macOS)

```bash
curl -fsSL https://raw.githubusercontent.com/relaystr/ndk/refs/heads/master/install.sh | bash
```

By default this installs the `ndk` binary to `~/.local/bin/ndk` and its shared libraries to `~/.local/lib` (user mode).

### Install options

```bash
# system-wide install (/usr/bin/ndk) — may require sudo
curl -fsSL https://raw.githubusercontent.com/relaystr/ndk/refs/heads/master/install.sh | bash -s -- --system

# pin a specific version
NDK_VERSION=v0.8.3 curl -fsSL https://raw.githubusercontent.com/relaystr/ndk/refs/heads/master/install.sh | bash

# latest pre-release
NDK_VERSION=latest-pre curl -fsSL https://raw.githubusercontent.com/relaystr/ndk/refs/heads/master/install.sh | bash
```

### Environment variables

| Variable | Default | Description |
|----------|---------|-------------|
| `NDK_VERSION` | `latest` | Version tag, `latest`, or `latest-pre` |
| `NDK_PRERELEASE` | `0` | When `1` and `NDK_VERSION=latest`, picks the latest pre-release |
| `NDK_INSTALL_MODE` | `user` | `user` or `system` |
| `NDK_INSTALL_DIR` | `~/.local/bin` | Binary destination (user mode) |
| `NDK_USER_LIB_DIR` | `~/.local/lib` | Shared libraries destination (user mode) |
| `NDK_SYSTEM_BIN_DIR` | `/usr/bin` | Binary destination (system mode) |
| `NDK_SYSTEM_LIB_DIR` | `/usr/lib` | Shared libraries destination (system mode) |

### PATH

If `~/.local/bin` is not in your `PATH`, add it to your shell profile:

```bash
export PATH="$PATH:$HOME/.local/bin"
```

Verify the installation:

```bash
ndk --version
```

See [releases](https://github.com/relaystr/ndk/releases) for available versions.

## Usage

```
ndk [global options] <command> [args]
```

Global options (must come before the command name):

| Option | Description |
|--------|-------------|
| `--version` | Show the package version |
| `-v` | Warning-level logging |
| `-vv` | Info-level logging |
| `-vvv` | Debug-level logging |
| `-h`, `--help` | Show help |

Run `ndk` with no arguments, or `ndk --help`, to list all commands.

## Commands

### `req` — query relays for events

Fetches events from one or more relays and prints them as JSON (one object per line).

```
ndk req [-k <kind>] [-l <limit>] [-t <seconds>] <relay1> [relay2 ...]
```

| Option | Description |
|--------|-------------|
| `-k`, `--kind <kind>` | Filter by event kind |
| `-l`, `--limit <limit>` | Limit number of events (default `10`) |
| `-t`, `--timeout <sec>` | Query timeout in seconds (default `12`) |

Relay URLs may be passed with or without the `wss://` scheme.

```bash
# last 5 text notes (kind 1) from a relay
ndk req -k 1 -l 5 wss://relay.damus.net

# kind-0 metadata from two relays, 5s timeout
ndk req -k 0 -t 5 relay.damus.net nos.lol
```

### `wallets` — manage Lightning/Cashu wallets

Wallet operations for NIP-47 (NWC) and Cashu wallets.

```
ndk wallets <list|add|remove|receive|send|balance|budget> [args]
```

| Sub-command | Description |
|-------------|-------------|
| `list` | List configured wallets |
| `add nwc <NWC_URI> [name]` | Add a Nostr Wallet Connect wallet |
| `add cashu <MINT_URL> [name]` | Add a Cashu wallet |
| `remove <walletId>` | Remove a wallet |
| `receive <amountSats> [walletId]` | Generate a receive invoice |
| `send <bolt11> [walletId]` | Pay a BOLT11 invoice |
| `balance [walletId]` | Show wallet balances |
| `budget [walletId]` | Show NWC budget info (NWC wallets only) |

```bash
ndk wallets list
ndk wallets add nwc "nostr+walletconnect://..."
ndk wallets add cashu "https://mint.example.com"
ndk wallets receive 1000
ndk wallets send "lnbc1..."
ndk wallets balance
ndk wallets budget
```

Run `ndk wallets help` for the full list of examples.
