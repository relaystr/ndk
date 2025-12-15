import 'package:ndk/domain_layer/entities/connection_source.dart';
import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

void main() async {
  group(
    "boostrap relay test",
    skip: true,
    () {
      test('nostr.wine in boostrap', () async {
        final ndk = Ndk(
          NdkConfig(
              engine: NdkEngine.JIT,
              eventVerifier: Bip340EventVerifier(),
              cache: MemCacheManager(),
              bootstrapRelays: [
                'wss://nostr.wine',
              ]),
        );

        final response = ndk.requests.query(filters: [
          Filter(limit: 5, kinds: [1])
        ]);

        await for (final event in response.stream) {
          /// works
          print('got event from nostr.wine: ${event.id}');
        }
      });

      test('nostr.wine connect after', () async {
        final ndk = Ndk(
          NdkConfig(
              engine: NdkEngine.JIT,
              eventVerifier: Bip340EventVerifier(),
              cache: MemCacheManager(),
              bootstrapRelays: []),
        );

        await ndk.relays.connectRelay(
          dirtyUrl: "wss://nostr.wine",
          connectionSource: ConnectionSource.seed,
        );

        final response = ndk.requests.query(filters: [
          Filter(limit: 5, kinds: [1])
        ]);

        await for (final event in response.stream) {
          ///todo does not work
          print('got event from nostr.wine: ${event.id}');
        }
      });

      test('nostr.wine connect in request', () async {
        final ndk = Ndk(
          NdkConfig(
              engine: NdkEngine.JIT,
              eventVerifier: Bip340EventVerifier(),
              cache: MemCacheManager(),
              bootstrapRelays: []),
        );

        final response = ndk.requests.query(
          filters: [
            Filter(limit: 5, kinds: [1]),
          ],
          explicitRelays: ["wss://nostr.wine"],
        );

        await for (final event in response.stream) {
          /// works
          print('got event from nostr.wine: ${event.id}');
        }
      });
    },
  );
}
