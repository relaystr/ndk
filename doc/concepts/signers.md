# Signers

Signers are responsible for cryptographic operations: signing events, encrypting and decrypting messages. NDK supports multiple signer types with a unified API.

## Signer Types

| Type | Description | Pending Requests |
|------|-------------|------------------|
| `Bip340EventSigner` | Local signer with private key | No (instant) |
| `Nip46EventSigner` | Remote signer via NIP-46 bunker | Yes |
| `Nip07EventSigner` | Browser extension (NIP-07) | Yes |
| `AmberEventSigner` | Android Amber app | Yes |

## Pending Requests

External signers (NIP-46, NIP-07, Amber) require user approval for operations. The unified pending requests API allows your UI to:

- Display pending operations to the user
- Cancel pending requests
- React to request completion

### Listening to Pending Requests

```dart
final signer = ndk.accounts.getLoggedAccount()?.signer;

// Stream-based (reactive)
signer?.pendingRequestsStream.listen((requests) {
  print('${requests.length} pending request(s)');
  for (final request in requests) {
    print('- ${request.method.protocolString} (${request.id})');
  }
});

// Snapshot (synchronous)
final currentRequests = signer?.pendingRequests ?? [];
```

### PendingSignerRequest Properties

```dart
class PendingSignerRequest {
  final String id;                    // Unique request identifier
  final SignerMethod method;          // signEvent, nip44Encrypt, etc.
  final DateTime createdAt;           // When the request was created
  final String signerPubkey;          // Public key of the signer
  final Nip01Event? event;            // Event being signed (for signEvent)
  final String? plaintext;            // Text being encrypted
  final String? ciphertext;           // Text being decrypted
  final String? counterpartyPubkey;   // Other party's pubkey (encrypt/decrypt)

  String? get content;                // Returns plaintext or ciphertext
}
```

### Cancelling Requests

```dart
// Cancel a specific request
final cancelled = signer.cancelRequest(requestId);

if (cancelled) {
  print('Request cancelled');
} else {
  print('Request not found');
}
```

When cancelled, the caller receives a `SignerRequestCancelledException`:

```dart
try {
  await signer.sign(event);
} on SignerRequestCancelledException catch (e) {
  print('User cancelled locally: ${e.requestId}');
}
```

### Handling Remote Rejections

When the user rejects a request on the remote signer (bunker, browser extension, Amber), the caller receives a `SignerRequestRejectedException`:

```dart
try {
  await signer.sign(event);
} on SignerRequestRejectedException catch (e) {
  print('User rejected on remote signer: ${e.requestId}');
  print('Original message: ${e.originalMessage}');
} on SignerRequestCancelledException catch (e) {
  print('User cancelled locally: ${e.requestId}');
}
```

| Exception | When thrown |
|-----------|-------------|
| `SignerRequestCancelledException` | `cancelRequest()` called locally |
| `SignerRequestRejectedException` | User rejected on remote signer |

## UI Example

```dart
StreamBuilder<List<PendingSignerRequest>>(
  stream: signer.pendingRequestsStream,
  builder: (context, snapshot) {
    final requests = snapshot.data ?? [];

    if (requests.isEmpty) {
      return Text('No pending requests');
    }

    return ListView.builder(
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return ListTile(
          title: Text(request.method.protocolString),
          subtitle: Text('Created ${request.createdAt}'),
          trailing: IconButton(
            icon: Icon(Icons.cancel),
            onPressed: () => signer.cancelRequest(request.id),
          ),
        );
      },
    );
  },
)
```

## Disposing Signers

Always dispose signers when done to avoid memory leaks:

```dart
await signer.dispose();
```

## When to Use

Use the pending requests API when:

- Building UI for external signers (bunkers, browser extensions, mobile apps)
- Showing users what operations are waiting for approval
- Allowing users to cancel stuck or unwanted requests
- Implementing request timeouts in your application
