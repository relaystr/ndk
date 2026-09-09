import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

import '../mocks/mock_event_verifier.dart';

/// a request sent to zero relays has nothing to wait for and must not hang
/// until the query timeout
void main() {
  const queryTimeout = Duration(seconds: 10);
  const maxAcceptable = Duration(seconds: 5);

  Future<void> expectFastEmptyQuery(Ndk ndk) async {
    bool timeoutTriggered = false;

    final stopwatch = Stopwatch()..start();
    final response = ndk.requests.query(
      filter: Filter(kinds: [Nip01Event.kTextNodeKind]),
      timeout: queryTimeout,
      timeoutCallback: () {
        timeoutTriggered = true;
      },
    );

    final events = await response.future;
    stopwatch.stop();

    expect(events, isEmpty);
    expect(timeoutTriggered, isFalse);
    expect(stopwatch.elapsed, lessThan(maxAcceptable));
  }

  group('no relay - query does not wait for the timeout', () {
    late Ndk ndk;

    tearDown(() async {
      await ndk.destroy();
    });

    test('relay sets engine', () async {
      ndk = Ndk(
        NdkConfig(
          eventVerifier: MockEventVerifier(),
          cache: MemCacheManager(),
          engine: NdkEngine.RELAY_SETS,
          bootstrapRelays: [],
        ),
      );

      await expectFastEmptyQuery(ndk);
    });

    test('jit engine', () async {
      ndk = Ndk(
        NdkConfig(
          eventVerifier: MockEventVerifier(),
          cache: MemCacheManager(),
          engine: NdkEngine.JIT,
          bootstrapRelays: [],
        ),
      );

      await expectFastEmptyQuery(ndk);
    });
  });
}
