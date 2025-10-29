import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

void main() {
  test('Query without trailling /', () async {
    final ndk = Ndk.emptyBootstrapRelaysConfig();

    final query = ndk.requests.query(
      filters: [
        Filter(kinds: [1], limit: 1),
      ],
      explicitRelays: ["wss://nostr-01.yakihonne.com"],
    );

    await query.future;
  });

  test('Query with trailling /', () async {
    final ndk = Ndk.emptyBootstrapRelaysConfig();

    final query = ndk.requests.query(
      filters: [
        Filter(kinds: [1], limit: 1),
      ],
      explicitRelays: ["wss://nostr-01.yakihonne.com/"],
    );

    await query.future;
  });

  test('Subscription without trailling /', () async {
    final ndk = Ndk.emptyBootstrapRelaysConfig();

    final query = ndk.requests.subscription(
      filters: [
        Filter(kinds: [1], limit: 1),
      ],
      explicitRelays: ["wss://nostr-01.yakihonne.com"],
    );

    await for (var event in query.stream) {
      print(event);
      break;
    }
  });

  test('Subscription with trailling /', () async {
    final ndk = Ndk.emptyBootstrapRelaysConfig();

    final query = ndk.requests.subscription(
      filters: [
        Filter(kinds: [1], limit: 1),
      ],
      explicitRelays: ["wss://nostr-01.yakihonne.com/"],
    );

    await for (var event in query.stream) {
      print(event);
      break;
    }
  });
}