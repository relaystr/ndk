---
icon: file-directory-symlink
label: Gift Wrap
---

[!badge variant="primary" text="low level"]

## Example

:::code source="../../packages/ndk/example/gift_wrap_example.dart" language="dart" range="17-32" title="" :::

:::code source="../../packages/ndk/example/gift_wrap_example.dart" language="dart" range="34-38" title="" :::

!!!
Gift Wrap depends on the logged in user (accounts usecase) make sure you are logged in with the right user
!!!

## When to use

You can use Gift Wrap to obscure metadata. It also encrypts the content using `nip44`. \
More information here:
[!ref target="blank" text="Nostr nip 59"](https://github.com/nostr-protocol/nips/blob/master/59.md)

## Current behavior

Gift wrap APIs:

- create rumors
- seal rumors
- wrap sealed rumors
- unwrap gift wraps
- read cached unwrap results when plaintext sidecars already exist

Decryption behavior:

- wrapped and sealed payload plaintext can be cached separately from the original events
- later unwraps can reuse cached plaintext
- cache-only unwrap is available when the required sidecars already exist
