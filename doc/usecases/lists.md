---
icon: list-unordered
---

[!badge variant="primary" text="high level"]

## Example

```dart

    final myset = await ndk.lists.getSinglePublicNip51RelaySet(
      name: "myset",
      publicKey:
          "3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d",
    );

    if (myset == null) {
      print("set not found");
      return;
    }
    print("recived a set with ${myset.elements.length} elements");

```

## How to use

We distinguish between public and private lists/sets. \
The methods are prefixed with public or private. \
Editing lists should be done via the provided broadcast methods.
