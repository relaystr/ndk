---
icon: arrow-down-left
---

[!badge variant="primary" text="low level"]

!!!warning Relay Misbehavior
Relays can misbehave and return events that do not match your query filters.
!!!

## Usage Example

:::code source="../../packages/ndk/example/basic_test.dart" language="dart" range="23-46" :::

## When to use

Requests should be used when no other use case fits your needs. \
There is `.query` and `.subscription` representing the nostr equivalent, `.subscription` should only be used when absolutely necessary. Many relays limit the amount of simultaneous subscriptions.

## Relay Authentication (NIP-42)

Some relays require authentication before serving requests. Use `authenticateAs` to specify which accounts should authenticate:

```dart
final account = Account(
  pubkey: myPubkey,
  type: AccountType.privateKey,
  signer: Bip340EventSigner(privateKey: myPrivkey, publicKey: myPubkey),
);

ndk.accounts.addAccount(pubkey: account.pubkey, type: account.type, signer: account.signer);

final response = ndk.requests.query(
  filter: Filter(kinds: [4], authors: [myPubkey]),
  authenticateAs: [account],
);
```

### Use cases

- **Multi-account clients**: Fetch private data (DMs, encrypted content) for multiple identities in a single query
- **Account aggregation**: Apps managing several accounts can authenticate all at once
- **Seamless account switching**: Pre-authenticate multiple accounts to avoid delays when switching

```dart
// Authenticate multiple accounts at once
final response = ndk.requests.query(
  filter: Filter(kinds: [4], authors: [user1Pubkey, user2Pubkey]),
  authenticateAs: [account1, account2],
);
```

If `authenticateAs` is not specified, NDK falls back to the currently logged-in account.
