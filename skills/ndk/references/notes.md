# Notes

## Local State

- Wallet DB: `wallets_db.db` (Sembast) — created in the current working directory
- Wallet IDs: `wallet_<microseconds-since-epoch>` — assigned at creation, stable across runs

## Wallet Types

| Type | Add arg | Budget | Notes |
|------|---------|--------|-------|
| NWC | `nwc <NWC_URI>` | ✅ | Connects to Nostr Wallet Connect endpoint |
| Cashu | `cashu <MINT_URL>` | ❌ | Fetches mint info on add; units from mint |

## Default Wallet Selection

Commands with optional `[walletId]`:
- Omit → uses `defaultWalletForReceiving` (or first wallet in list)
- Multiple wallets → pass explicit `walletId` to avoid wrong wallet

## Event Verifier

Uses Rust verifier (`RustEventVerifier`) with automatic fallback to `Bip340EventVerifier` if native library unavailable. Fallback warning printed to stderr.

## Verbosity / Logging

`-v/-vv/-vvv` must appear **before** the command name:

```bash
ndk -vv wallets list     # ✅ info-level logs
ndk wallets list -vv     # ❌ error: -vv must be provided before command name
```

## Supported Platforms

Linux (x64, arm64), macOS (arm64). Windows: not supported by install script.
