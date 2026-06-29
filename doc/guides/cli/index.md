---
label: NDK CLI
title: NDK CLI
icon: terminal
order: 99.5
---

# NDK CLI

NDK ships a standalone command line interface for querying relays, managing
identities, publishing events, and operating Lightning/Cashu wallets — without
writing any Dart code. It is a prebuilt binary — no Dart or Flutter toolchain
required.

## Commands

| Command | Description |
|---------|-------------|
| [`req`](req.md) | Query relays for events |
| [`broadcast`](broadcast.md) | Publish events to relays |
| [`accounts`](accounts.md) | Manage local identities (login, logout, list, switch, whoami) |
| [`wallets`](wallets.md) | Lightning / Cashu wallet operations |
| [`zaps`](zaps.md) | NIP-57 zap operations (invoice, zap, receipts) |
| [`files`](files.md) | High-level file management (upload, download, delete, check) |
| [`blossom`](blossom.md) | Low-level Blossom operations (upload, download, delete, list, mirror, check, servers) |

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

## Persistence & local state

The CLI stores the following files in your working directory (or the
locations noted):

| File | Purpose |
|------|---------|
| `~/.ndk/accounts.json` | Persisted identities (private keys / bunker connections). Override with `NDK_ACCOUNTS_FILE`. |
| `wallets_db.db` | Wallet definitions and transaction history. |
| `ndk_cache.db` | Event cache, Cashu proofs/keysets/mint infos. |
| `NDK_CASHU_SEED` | Environment variable supplying the Cashu seed phrase. |
