<img align="right" src="https://framerusercontent.com/assets/zipB5Tdnkw0u2uMIStFerslkTa4.png" width="200px" />

[![Pub](https://img.shields.io/pub/v/ndk_nwc.svg)](https://pub.dev/packages/ndk_nwc)
[![License](https://img.shields.io/github/license/relaystr/ndk.svg)](LICENSE.txt)
#
#

# NWC

Nostr Wallet Connect implementation for dart NDK.
https://nwc.dev

## Resources
- https://github.com/getAlby/awesome-nwc for more info how to get a wallet supporting NWC
- https://github.com/nostr-protocol/nips/blob/master/47.md for protocol spec 

## Usage

```dart
  Ndk ndk = Ndk.emptyBootstrapRelaysConfig();
  Nwc nwc = Nwc(ndk);

  NwcConnection connection = await nwc.connect(Platform.environment['NWC_URI']!);

  GetBalanceResponse balanceResponse = await nwc.getBalance(connection);
  print("Balance: ${balanceResponse.balanceSats} sats");

  MakeInvoiceResponse makeInvoice = await nwc.makeInvoice(connection, amountSats: 100);
  print("paying ${makeInvoice.amountSat} sats invoice: ${makeInvoice.invoice}");

  PayInvoiceResponse payInvoice = await nwc.payInvoice(connection, invoice: makeInvoice.invoice);
  print("preimage: ${payInvoice.preimage}");

  await nwc.close();
  await ndk.close();
```

> **more [examples 🔗](https://github.com/relaystr/ndk/tree/master/packages/nwc/example)**
