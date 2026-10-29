# running the examples

These examples use a local Sembast database at `example/wallets/wallets_db.db`, so added wallets stay available between runs.

List stored wallets:

`dart example/wallets/list_wallets.dart`

Get balances for the first stored wallet, or set `WALLET_ID`:

`dart example/wallets/get_balance.dart`

Add an NWC wallet:

`NWC_URI=nostr+walletconnect://... dart example/wallets/add_nwc_wallet.dart`

Add a Cashu wallet:

`MINT_URL=https://mint.example.com dart example/wallets/add_cashu_wallet.dart`

Create an invoice with the first stored wallet, or set `WALLET_ID`:

`AMOUNT_SATS=1000 dart example/wallets/receive.dart`

Pay an invoice with the first stored wallet, or set `WALLET_ID`:

`INVOICE=lnbc1... dart example/wallets/send.dart`

Optional:

- `WALLET_NAME` customizes the name when adding a wallet.
- `WALLET_ID` selects a specific stored wallet for `receive.dart` and `send.dart`.
