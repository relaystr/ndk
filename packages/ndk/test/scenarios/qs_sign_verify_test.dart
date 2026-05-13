// ignore_for_file: avoid_print, non_constant_identifier_names

import 'package:ndk/data_layer/repositories/signers/qs_rust_event_signer.dart';
import 'package:ndk/data_layer/repositories/verifiers/qs_rust_event_verifier_native.dart';
import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

import '../tools/simple_profiler.dart';

void main() async {
  group(
    "qs_sign + qs_verify",
    skip: true,
    () {
      test('dev - test', () async {
        final profiler = SimpleProfiler('QS Sign + Verify');

        final LEVEL = 2;

        final myKeyPair = QsRustEventSigner.generateKeypair(level: LEVEL);

        final eventVerifier = QsRustEventVerifier(level: LEVEL);
        final signer = QsRustEventSigner(level: LEVEL, keypair: myKeyPair);

        final usignedEvent = Nip01Event(
          content: "hello",
          kind: 1,
          pubKey: '',
          tags: [],
        );

        profiler.checkpoint('Created unsigned event');
        final signedEvent = await signer.sign(usignedEvent);

        profiler.checkpoint('Event signed with QS signature');
        final isValid = await eventVerifier.verify(signedEvent);

        profiler.checkpoint('QS sign + verify completed, valid: $isValid');

        expect(isValid, true);

        print("\n\nLevel: $LEVEL\n");
        print("Signature: ${signedEvent.sig}\n");
        print("Event ID: ${signedEvent.id}\n");
        print("Public Key: ${signedEvent.pubKey}\n\n");
      });

      test('dev - bulk speed test', () async {
        final profiler = SimpleProfiler('QS Bulk Sign + Verify');

        final LEVEL = 5;
        final MESSAGE_COUNT = 1000; // Configurable via variable

        final myKeyPair = QsRustEventSigner.generateKeypair(level: LEVEL);

        final eventVerifier = QsRustEventVerifier(level: LEVEL);
        final signer = QsRustEventSigner(level: LEVEL, keypair: myKeyPair);

        profiler.checkpoint('Started bulk test with $MESSAGE_COUNT messages');

        // Create all unsigned events first
        final unsignedEvents = List.generate(
          MESSAGE_COUNT,
          (index) => Nip01Event(
            content: "hello message $index",
            kind: 1,
            pubKey: '',
            tags: [],
          ),
        );

        profiler.checkpoint('Created $MESSAGE_COUNT unsigned events');

        // Sign all events in parallel
        final signedEvents = await Future.wait(
          unsignedEvents.map((event) => signer.sign(event)),
        );

        profiler.checkpoint('Signed $MESSAGE_COUNT events');

        // Verify all events in parallel
        final isValidations = await Future.wait(
          signedEvents.map((signedEvent) => eventVerifier.verify(signedEvent)),
        );

        profiler.checkpoint('Verified $MESSAGE_COUNT events');

        // Check if all verifications passed
        bool allValid = isValidations.every((valid) => valid);
        int failedCount = isValidations.where((valid) => !valid).length;

        final checkpointString =
            'QS sign + verify completed: $MESSAGE_COUNT total, $failedCount failed';
        profiler.checkpoint(checkpointString);

        expect(allValid, true);

        profiler.end();

        print("Events processed: $MESSAGE_COUNT");
        print("Verification failures: $failedCount");
        print("Used Level: $LEVEL\n\n");
      });
    },
  );
}
