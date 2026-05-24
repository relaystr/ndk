# Wallets Command Reference

```
ndk wallets <sub-command> [args]
```

Local wallet state stored in `wallets_db.db` (Sembast). Wallets persist between runs.

---

## list

```bash
ndk wallets list
```

Lists all stored wallets with id, name, type, supported units, and default flags (`default-receive`, `default-send`).

---

## add

### NWC wallet

```bash
ndk wallets add nwc "<NWC_URI>" [name]
```

`NWC_URI` format: `nostr+walletconnect://...`

```bash
ndk wallets add nwc "nostr+walletconnect://abc123..." "My NWC Wallet"
```

### Cashu wallet

```bash
ndk wallets add cashu "<MINT_URL>" [name]
```

Fetches mint info from network to detect supported units.

```bash
ndk wallets add cashu "https://mint.minibits.cash/Bitcoin" "Minibits"
```

---

## remove

```bash
ndk wallets remove <walletId>
```

`walletId` format: `wallet_<microseconds>` (shown in `list` output).

---

## receive

Generate Lightning invoice for a specific amount:

```bash
ndk wallets receive <amountSats>
ndk wallets receive <amountSats> <walletId>   # specific wallet
```

Prints the bolt11 invoice to stdout.

---

## send

Pay a bolt11 invoice:

```bash
ndk wallets send "<bolt11>"
ndk wallets send "<bolt11>" <walletId>   # specific wallet
```

Output: `preimage`, `feesPaid` (msats), error fields if any.

---

## balance

```bash
ndk wallets balance
ndk wallets balance <walletId>
```

Prints balances per unit (e.g. `sat`) for the wallet. Defaults to `defaultWalletForReceiving` or first wallet.

Timeout: 12 seconds.

---

## budget

NWC wallets only:

```bash
ndk wallets budget
ndk wallets budget <walletId>
```

Output: `used` (sats), `total` (sats), `remaining` (sats), `renewal period`, `renews at`.

---

## Wallet ID

Format: `wallet_<microseconds-since-epoch>` — assigned at creation time.  
When only one wallet exists, `walletId` argument is optional.  
With multiple wallets, pass explicit `walletId` to avoid ambiguity.
