# running the examples

You need a `nostr+walletconnect://...` uri from your NWC wallet service provider.

see https://github.com/getAlby/awesome-nwc for more info how to get a wallet supporting NWC

`NWC_URI=nostr+walletconnect://.... dart connect_get_info.dart`

for more logging

`NWC_URI=nostr+walletconnect://.... dart --enable-asserts connect_get_info.dart`

## NWC-321 pay and receive

Pay a BOLT11 invoice through a BIP-321 `lightning` instruction:

`NWC_URI=nostr+walletconnect://.... INVOICE=lnbc... dart pay.dart`

If the invoice has no amount, also provide `AMOUNT_MSAT`:

`NWC_URI=nostr+walletconnect://.... INVOICE=lnbc... AMOUNT_MSAT=21000 dart pay.dart`

Create a fixed-amount BIP-321 URI containing a BOLT11 instruction:

`NWC_URI=nostr+walletconnect://.... AMOUNT_MSAT=21000 DESCRIPTION=hello dart receive.dart`

Omit `AMOUNT_MSAT` to request a variable-amount URI.
