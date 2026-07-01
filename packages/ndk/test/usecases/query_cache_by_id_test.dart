import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

import '../mocks/mock_event_verifier.dart';

void main() {
  test('save signed event in cache then query it back with an ids-only filter',
      () async {
    final ndk = Ndk(NdkConfig(
      eventVerifier: MockEventVerifier(),
      cache: MemCacheManager(),
      bootstrapRelays: [],
    ));

    final KeyPair keyPair = Bip340.generatePrivateKey();

    final signedEvent = Nip01Utils.signWithPrivateKey(
      event: Nip01Event(
        pubKey: keyPair.publicKey,
        kind: Nip01Event.kTextNodeKind,
        tags: [],
        content: "hello from cache",
      ),
      privateKey: keyPair.privateKey!,
    );

    await ndk.config.cache.saveEvent(signedEvent);

    final stopwatch = Stopwatch()..start();
    final events =
        await ndk.requests.query(filter: Filter(ids: [signedEvent.id])).future;
    stopwatch.stop();

    expect(events.length, equals(1));
    expect(events.first.id, equals(signedEvent.id));
    expect(events.first.sig, equals(signedEvent.sig));
    expect(events.first.content, equals("hello from cache"));

    expect(
      stopwatch.elapsedMilliseconds,
      lessThan(50),
      reason: 'an ids-only query fully served by cache should return '
          'immediately, not wait for the query timeout',
    );

    await ndk.destroy();
  });
}
