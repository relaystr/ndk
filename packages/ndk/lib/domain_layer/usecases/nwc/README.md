<img src="https://framerusercontent.com/assets/zipB5Tdnkw0u2uMIStFerslkTa4.png" width="300px" />

Nostr Wallet Connect implementation for dart NDK.
https://nwc.dev

## Resources
- https://github.com/getAlby/awesome-nwc for more info how to get a wallet supporting NWC
- https://github.com/nostr-protocol/nips/blob/master/47.md for protocol spec 

## Usage

```dart
  Ndk ndk = Ndk.emptyBootstrapRelaysConfig();

  NwcConnection connection = await ndk.nwc.connect(Platform.environment['NWC_URI']!);

  GetBalanceResponse balanceResponse = await ndk.nwc.getBalance(connection);
  print("Balance: ${balanceResponse.balanceSats} sats");

  MakeInvoiceResponse makeInvoice = await ndk.nwc.makeInvoice(connection, amountSats: 100);
  print("paying ${makeInvoice.amountSat} sats invoice: ${makeInvoice.invoice}");

  PayInvoiceResponse payInvoice = await ndk.nwc.payInvoice(connection, invoice: makeInvoice.invoice);
  print("preimage: ${payInvoice.preimage}");

  await ndk.destroy();
```

> **more [examples 🔗](https://github.com/relaystr/ndk/tree/master/packages/ndk/example/nwc)**
