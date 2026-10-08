# Requests & Subscriptions

Low-level relay queries via `ndk.requests`.

## Query (one-shot)

```dart
final response = ndk.requests.query(
  filters: [Filter(kinds: [1], limit: 20)],
);

// Stream of events as they arrive
await for (final event in response.stream) {
  print(event.content);
}
```

## Subscription (live stream)

```dart
final sub = ndk.requests.subscription(
  filters: [Filter(kinds: [1], authors: [pubkey])],
);

sub.stream.listen((event) {
  print(event);
});

// Cancel when done
sub.close();
```

## Filter fields

```dart
Filter(
  ids: ['<event-id>'],           // specific event IDs
  authors: ['<hex-pubkey>'],     // specific authors
  kinds: [1, 6, 7],              // event kinds
  tags: {'e': ['<event-id>']},   // tag filters (#e, #p, etc.)
  since: DateTime.now().subtract(Duration(hours: 1)),
  until: DateTime.now(),
  limit: 50,
  search: 'keyword',             // NIP-50 search (if relay supports)
)
```

## Response object

```dart
final response = ndk.requests.query(filters: [...]);

response.stream        // Stream<Nip01Event>
response.future        // Future<List<Nip01Event>> — waits for EOSE
response.requestId     // String
response.close()       // cancel early
```

## Nip01Event fields

```dart
event.id         // String — event ID
event.pubkey     // String — author hex pubkey
event.kind       // int
event.content    // String
event.tags       // List<List<String>>
event.createdAt  // int — unix timestamp
event.sig        // String — signature
```

## High-level usecases (prefer over raw requests)

| Usecase | Accessor | Description |
| ------- | -------- | ----------- |
| Metadata | `ndk.metadata` | Fetch user profiles |
| Follows | `ndk.follows` | Contact lists |
| Lists | `ndk.lists` | NIP-51 lists |
| NIP-05 | `ndk.nip05` | Verify/fetch NIP-05 |
| Search | `ndk.search` | NIP-50 search (experimental) |
