import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';
import 'dart:io';

import '../mocks/mock_event_verifier.dart';
import '../mocks/mock_relay.dart';

void main() {
  Nip01Event textNote(KeyPair key2) {
    return Nip01Event(
        kind: Nip01Event.kTextNodeKind,
        pubKey: key2.publicKey,
        content: "some note from key $key2}",
        tags: [],
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000);
  }

  group('Timeout - query', () {
    KeyPair key1 = Bip340.generatePrivateKey();
    late MockRelay relay1;
    late Ndk ndk;
    Map<KeyPair, Nip01Event> key1TextNotes = {key1: textNote(key1)};

    // startup and teardown
    setUp(() async {
      relay1 = MockRelay(name: "relay 1");
      await relay1.startServer();
      relay1.textNotes = key1TextNotes;
    });

    tearDown(() async {
      await ndk.destroy();
      await relay1.stopServer();
    });

    test('timeout does not trigger on normal request', () async {
      NdkConfig config = NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: MemCacheManager(),
        engine: NdkEngine.RELAY_SETS,
        bootstrapRelays: [relay1.url],
      );

      ndk = Ndk(config);

      bool timeoutTriggered = false;
      bool timeoutUserTriggered = false;

      final response = ndk.requests.query(
          filters: [
            Filter(authors: [key1.publicKey])
          ],
          // Allow enough headroom to remain stable under parallel suite load.
          timeout: Duration(seconds: 4),
          timeoutCallback: () {
            timeoutTriggered = true;
          },
          timeoutCallbackUserFacing: () {
            timeoutUserTriggered = true;
          });

      // wait for completion
      await response.future;

      expect(timeoutUserTriggered, isFalse);
      expect(timeoutTriggered, isFalse);
    });

    test('timeout triggers', () async {
      NdkConfig config = NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: MemCacheManager(),
        engine: NdkEngine.RELAY_SETS,
        bootstrapRelays: ["invalid"],
      );

      ndk = Ndk(config);

      bool timeoutTriggered = false;
      bool timeoutUserTriggered = false;

      final response = ndk.requests.query(
          filters: [
            Filter(authors: ["unknown"])
          ],
          // short to fail fast
          timeout: Duration(seconds: 1),
          timeoutCallback: () {
            timeoutTriggered = true;
          },
          timeoutCallbackUserFacing: () {
            timeoutUserTriggered = true;
          });

      // wait for completion
      await response.future;

      expect(timeoutUserTriggered, isTrue);
      expect(timeoutTriggered, isTrue);
    });

    test('timeout triggers default ndk values within expected time window', () async {
      const Duration myTimeout = Duration(seconds: 1);
      NdkConfig config = NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: MemCacheManager(),
        engine: NdkEngine.RELAY_SETS,
        bootstrapRelays: ["invalid"],
        defaultQueryTimeout: myTimeout,
      );

      ndk = Ndk(config);

      bool timeoutTriggered = false;
      bool timeoutUserTriggered = false;

      // Start the stopwatch
      final stopwatch = Stopwatch()..start();

      final response = ndk.requests.query(
        filters: [
          Filter(authors: ["unknown"])
        ],
        // short to fail fast
        timeoutCallback: () {
          timeoutTriggered = true;
        },
        timeoutCallbackUserFacing: () {
          timeoutUserTriggered = true;
        },
      );

      // Wait for completion
      await response.future;

      // Stop the stopwatch
      stopwatch.stop();

      // Get the elapsed time
      final elapsedMilliseconds = stopwatch.elapsedMilliseconds;

      // Assert that timeout callbacks were triggered
      expect(timeoutUserTriggered, isTrue);
      expect(timeoutTriggered, isTrue);

      // Assert that the timeout occurred within the expected time window
      // Adjust these values based on your expected timeout duration
      expect(elapsedMilliseconds, greaterThanOrEqualTo(myTimeout.inMilliseconds - 1000)); // lower bound
      expect(elapsedMilliseconds, lessThanOrEqualTo(myTimeout.inMilliseconds + 1000)); // upper bound
    });
  });
}
