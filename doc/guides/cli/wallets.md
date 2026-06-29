---
label: wallets
title: wallets
icon: credit-card
order: 4
---

# `wallets` — manage Lightning / Cashu wallets

Wallet operations for NIP-47 (NWC) and Cashu wallets.

```
ndk wallets <sub-command> [args]
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
| `budget [walletId]` | Show NWC budget info (NWC only) |
| `set-default <walletId> [receive\|send\|both]` | Set default wallet (default scope: `both`) |
| `melt <bolt11> [walletId] [--seed <mnemonic>]` | Pay a BOLT11 invoice with Cashu ecash |
| `mint <amountSats> [walletId] [--seed <mnemonic>] [--wait]` | Mint Cashu tokens from a quote (add `--wait` to poll until paid) |
| `swap-receive <cashuToken> [--seed <mnemonic>]` | Receive an incoming Cashu token |
| `swap-spend <amountSats> [walletId] [--seed <mnemonic>]` | Create a sendable Cashu token from your balance |
| `pay-stats [walletId] [--limit N]` | Show recent transactions |

```bash
ndk wallets list
ndk wallets add nwc "nostr+walletconnect://..."
ndk wallets add cashu "https://mint.example.com"
ndk wallets receive 1000
ndk wallets send "lnbc1..."
ndk wallets balance
ndk wallets budget
ndk wallets set-default wallet_123 send
ndk wallets pay-stats --limit 50
```

## Cashu operations and the seed phrase

All Cashu state-modifying operations (`melt`, `mint`, `swap-receive`,
`swap-spend`) require the wallet's seed phrase. Provide it via `--seed`:

```bash
ndk wallets mint 100 --wait --seed "word1 word2 ... word12"
ndk wallets melt "lnbc1..." --seed "word1 word2 ... word12"
ndk wallets swap-receive "cashuA..."
```

…or export `NDK_CASHU_SEED` once per shell session:

```bash
export NDK_CASHU_SEED="word1 word2 ... word12"
ndk wallets mint 100 --wait
```

The mint sub-command prints a BOLT11 invoice; pay it externally and
re-run with `--wait` (or pass `--wait` up front) to poll until the mint
confirms payment and issues tokens. Cashu proofs, keysets and counters
persist in `ndk_cache.db` next to `wallets_db.db`, so state survives
across invocations.

Run `ndk wallets help` for the full list of examples.
