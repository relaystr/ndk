---
icon: person
---

[!badge variant="primary" text="high level"]

## Example

:::code source="../../packages/ndk/example/account_test.dart" language="dart" range="16-34" title="" :::

## When to use

Use it to log in an account. 
You can use several types of accounts:

- `loginPrivateKey`
- `loginPublicKey` (read-only)
- `loginExternalSigner` (capabilities will be managed by external signer)

An account logged in is needed in order to use [broadcast](/usecases/broadcast.md), and only if the signer used is able to sign.

You can switch between several logged in accounts with `switchAccount(pubkey:...)`
