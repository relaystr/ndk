---
icon: plug
---
[!badge variant="primary" text="high level"]

## Example

:::code source="../../packages/ndk/example/nwc/get_balance.dart" language="dart" range="15-21" title="connect, get balance" :::

:::code source="../../packages/ndk/example/nwc/pay_invoice.dart" language="dart" range="19-19" title="pay invoice" :::


:::code source="../../packages/ndk/example/nwc/notifications.dart" language="dart" range="14-20" title="notifications" :::

## How to use

You need a `nostr+walletconnect://...` uri from your NWC wallet service provider.

`NwcConnection.supportedExtensions` lists recognized extension identifiers from
the wallet's info event. It includes `NwcExtension.lookupPayment` (`09`) and
`NwcExtension.bolt12` (`12`) when the wallet advertises them. Unknown identifiers
are ignored.

see https://github.com/getAlby/awesome-nwc for more info how to get a wallet supporting NWC
