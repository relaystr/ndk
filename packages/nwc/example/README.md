# running the examples

You need a `nostr+walletconnect://...` uri from your NWC wallet service provider.

see https://github.com/getAlby/awesome-nwc for more info how to get a wallet supporting NWC

`NWC_URI=nostr+walletconnect://.... dart ./example/connect_get_info.dart`

for more logging

`NWC_URI=nostr+walletconnect://.... dart --enable-asserts ./example/connect_get_info.dart`