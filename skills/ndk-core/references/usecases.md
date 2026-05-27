# Usecases Overview

All accessible via `ndk.<accessor>`.

## Stable

| Accessor | Type | Description |
| -------- | ---- | ----------- |
| `ndk.requests` | `Requests` | Low-level relay queries and subscriptions |
| `ndk.broadcast` | `Broadcast` | Publish events to relays |
| `ndk.accounts` | `Accounts` | Identity/account management |
| `ndk.bunkers` | `Bunkers` | NIP-46 remote signing |
| `ndk.relays` | `RelayManager` | Relay connections and management |
| `ndk.follows` | `Follows` | Contact lists (NIP-02) |
| `ndk.metadata` | `Metadatas` | User profile metadata (NIP-01 kind 0) |
| `ndk.userRelayLists` | `UserRelayLists` | NIP-65 relay lists |
| `ndk.lists` | `Lists` | NIP-51 generic lists |
| `ndk.relaySets` | `RelaySets` | Calculate relay sets for outbox model |
| `ndk.nip05` | `Nip05Usecase` | NIP-05 verify and fetch |
| `ndk.files` | `Files` | File upload/download (Blossom) |
| `ndk.blossom` | `Blossom` | Blossom low-level (advanced) |
| `ndk.blossomUserServerList` | `BlossomUserServerList` | Manage Blossom server list |
| `ndk.giftWrap` | `GiftWrap` | NIP-59 gift wrap create/unwrap |
| `ndk.connectivity` | `Connectivy` | Relay connectivity events |
| `ndk.proofOfWork` | `ProofOfWork` | PoW event generation |

## Experimental

| Accessor | Type | Description |
| -------- | ---- | ----------- |
| `ndk.nwc` | `Nwc` | Nostr Wallet Connect |
| `ndk.zaps` | `Zaps` | Zap send/receive |
| `ndk.search` | `Search` | NIP-50 relay search |
| `ndk.cashu` | `Cashu` | Cashu e-cash wallet |
| `ndk.wallets` | `Wallets` | Combined NWC + Cashu wallet |
| `ndk.fetchedRanges` | `FetchedRanges` | Track fetched time ranges per relay |
| `ndk.nip77` | `Nip77` | Negentropy set reconciliation |
| `ndk.ta` / `ndk.trustedAssertions` | `TrustedAssertions` | NIP-85 trusted metrics |

## Broadcast

```dart
// Publish a signed event
final event = Nip01Event(
  pubkey: pubkey,
  kind: 1,
  content: 'hello nostr',
  tags: [],
);

final response = await ndk.broadcast.broadcastEvent(
  event,
  signer: mySigner,
);

await for (final result in response.stream) {
  print('${result.relay}: ${result.ok}');
}
```

## Metadata

```dart
final metadata = await ndk.metadata.loadMetadata(pubkey);
print(metadata?.name);
print(metadata?.picture);
print(metadata?.nip05);
```

## Follows

```dart
final contactList = await ndk.follows.getContactList(pubkey);
contactList?.contacts; // List<Contact>
```

## Files (Blossom)

```dart
// Upload
final result = await ndk.files.upload(
  fileBytes: bytes,
  mimeType: 'image/png',
  signer: mySigner,
);

// Download
final data = await ndk.files.download(url);
```
