# Commands Overview

```
ndk [global options] <command> [args]
```

## Global Options

| Flag | Description |
|------|-------------|
| `--version` | Print package version |
| `-v` | Warning-level logging |
| `-vv` | Info-level logging |
| `-vvv` | Debug-level logging |
| `-h`, `--help` | Show help |

> Global options must appear **before** the command name.

## Commands

| Command | Description |
|---------|-------------|
| `wallets` | Wallet operations — list, add, remove, receive, send, balance, budget |
| `req` | Query Nostr relays for events |
| `help` | Show help |

See detailed references:
- [wallets.md](wallets.md)
- [req.md](req.md)
