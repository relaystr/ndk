---
icon: list-unordered
---

[!badge variant="primary" text="high level"]

## Example

```dart
final myset = await ndk.lists.getSetByName(
  name: "myset",
  kind: Nip51List.kRelaySet,
  customSigner: mySigner,
);

if (myset == null) {
  print("set not found");
  return;
}
print("received a set with ${myset.elements.length} elements");
```

## How to use

We distinguish between **lists** and **sets**:
- **Lists**: Single lists identified by kind (e.g., bookmarks, mute list)
- **Sets**: Named collections identified by kind + name/d-tag (e.g., relay sets, follow sets)

Both can have public and private (encrypted) elements.

### Lists Methods

#### getSingleNip51List

Retrieves a NIP-51 list by kind.

:::code source="../../packages/ndk/lib/domain_layer/usecases/lists/lists.dart" language="dart" range="53-69" title="" :::

#### addElementToList

Adds an element to a list. Creates the list if it doesn't exist.

:::code source="../../packages/ndk/lib/domain_layer/usecases/lists/lists.dart" language="dart" range="95-114" title="" :::

#### removeElementFromList

Removes an element from a list.

:::code source="../../packages/ndk/lib/domain_layer/usecases/lists/lists.dart" language="dart" range="149-166" title="" :::

### Sets Methods

#### getSetByName

Gets a specific set by name (d-tag) and kind.

:::code source="../../packages/ndk/lib/domain_layer/usecases/lists/lists.dart" language="dart" range="268-285" title="" :::

#### getPublicSets

Returns a stream of all public sets for a given public key and kind.

:::code source="../../packages/ndk/lib/domain_layer/usecases/lists/lists.dart" language="dart" range="328-342" title="" :::

#### addElementToSet

Adds an element to a named set. Creates the set if it doesn't exist.

:::code source="../../packages/ndk/lib/domain_layer/usecases/lists/lists.dart" language="dart" range="347-367" title="" :::

#### removeElementFromSet

Removes an element from a named set.

:::code source="../../packages/ndk/lib/domain_layer/usecases/lists/lists.dart" language="dart" range="403-424" title="" :::

#### setCompleteSet

Overwrites or creates a complete set. **Warning:** This replaces the entire set.

:::code source="../../packages/ndk/lib/domain_layer/usecases/lists/lists.dart" language="dart" range="471-485" title="" :::

#### deleteSet

Deletes a set by name and broadcasts a deletion event.

:::code source="../../packages/ndk/lib/domain_layer/usecases/lists/lists.dart" language="dart" range="514-528" title="" :::

## Common Use Cases

### Relay Sets
```dart
// Add relay to a set
await ndk.lists.addElementToSet(
  name: "my-relays",
  tag: "relay",
  value: "wss://relay.example.com",
  kind: Nip51List.kRelaySet,
);

// Get a relay set
final relaySet = await ndk.lists.getSetByName(
  name: "my-relays",
  kind: Nip51List.kRelaySet,
);
```

### Bookmarks
```dart
// Add bookmark
await ndk.lists.addElementToList(
  kind: Nip51List.kBookmarks,
  tag: "e",
  value: eventId,
);

// Get bookmarks
final bookmarks = await ndk.lists.getSingleNip51List(
  Nip51List.kBookmarks,
  mySigner,
);
```

### Follow Sets
```dart
// Add to follow set
await ndk.lists.addElementToSet(
  name: "close-friends",
  tag: "p",
  value: pubkey,
  kind: Nip51List.kFollowSet,
);

// Stream all public follow sets
ndk.lists.getPublicSets(
  kind: Nip51List.kFollowSet,
  publicKey: somePubkey,
).listen((sets) {
  print("Found ${sets?.length ?? 0} follow sets");
});
```
