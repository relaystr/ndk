# NIP-07 Event Signer

Nip 07 signer compatible with ndk.

Main package: [🔗 Dart Nostr Development Kit (NDK)](https://pub.dev/packages/ndk)

### Info

Nip 07 signer are async so use `await Nip07EventSigner().getPublicKeyAsync();` to get the pubKey. `Nip07EventSigner().getPublicKey` work but it get the pubKey from a cache and you still need to call `await Nip07EventSigner().getPublicKeyAsync();` before be able to use `Nip07EventSigner().getPublicKey`.