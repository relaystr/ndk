import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

void main() {
  test('order 1', () async {
    final ndk = Ndk(
      NdkConfig(
        eventVerifier: Bip340EventVerifier(),
        cache: MemCacheManager(),
        bootstrapRelays: [
          "wss://nostr-01.uid.ovh",
          "wss://nostr-02.uid.ovh",
          "wss://relay.camelus.app",
          "wss://nostr-01.yakihonne.com",
          "wss://relay.primal.net",
          "wss://relay.damus.io",
          "wss://relay.snort.social",
          "wss://purplepag.es",
          "wss://nos.lol",
        ],
        logLevel: LogLevel.off,
      ),
    );

    final query = ndk.requests.query(
      filters: [
        Filter(kinds: [1984]),
        Filter(kinds: [31988]),
      ],
    );

    final events = await query.future;

    expect(events.where((e) => e.kind == 31988).length, greaterThan(0));
    expect(events.where((e) => e.kind == 1984).length, greaterThan(0));

    await ndk.destroy();
  });

  test('order 2', () async {
    final ndk = Ndk(
      NdkConfig(
        eventVerifier: Bip340EventVerifier(),
        cache: MemCacheManager(),
        bootstrapRelays: [
          "wss://nostr-01.uid.ovh",
          "wss://nostr-02.uid.ovh",
          "wss://relay.camelus.app",
          "wss://nostr-01.yakihonne.com",
          "wss://relay.primal.net",
          "wss://relay.damus.io",
          "wss://relay.snort.social",
          "wss://purplepag.es",
          "wss://nos.lol",
        ],
        logLevel: LogLevel.off,
      ),
    );

    final query = ndk.requests.query(
      filters: [
        Filter(kinds: [31988]),
        Filter(kinds: [1984]),
      ],
    );

    final events = await query.future;

    expect(events.where((e) => e.kind == 31988).length, greaterThan(0));
    expect(events.where((e) => e.kind == 1984).length, greaterThan(0));

    await ndk.destroy();
  });
}
