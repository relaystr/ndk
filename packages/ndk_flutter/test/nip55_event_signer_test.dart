import 'package:flutter_test/flutter_test.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_flutter/data_layer/data_sources/nip55_signer.dart';
import 'package:ndk_flutter/data_layer/repositories/signers/nip55_event_signer.dart';

class _FakeNip55Signer extends Nip55Signer {
  _FakeNip55Signer(this.response);

  final Map<dynamic, dynamic> response;

  @override
  Future<Map<dynamic, dynamic>> signEvent({
    required String currentUser,
    required String eventJson,
    String? id,
  }) async {
    return response;
  }
}

void main() {
  const privateKey =
      'e4bd52924bce6a9c58d2decc7fe91b376d6a6513fc615aabc9e071f2b436b127';
  const publicKey =
      '953f12b4f6966a289fde9adfc511e00a66cfa4cb9d69551dee51f3f387e8e277';
  const stalePublicKey =
      'e247d5da03bab4206b4d6ef5d9db0e175e0dbf51585fa16345dd53abdd2d9259';

  group('Nip55EventSigner', () {
    test(
      'sign returns the event the external signer actually signed',
      () async {
        final externalSigner = Bip340EventSigner(
          privateKey: privateKey,
          publicKey: publicKey,
        );
        final actuallySigned = await externalSigner.sign(
          Nip01Event(
            pubKey: publicKey,
            kind: 1,
            tags: [
              ['t', 'nostr'],
            ],
            content: 'test content',
            createdAt: 1234567890,
          ),
        );

        final signer = Nip55EventSigner(
          publicKey: stalePublicKey,
          nip55Signer: _FakeNip55Signer({
            'signature': actuallySigned.sig,
            'event': Nip01EventModel.fromEntity(actuallySigned).toJsonString(),
          }),
        );
        addTearDown(signer.dispose);

        final signedEvent = await signer.sign(
          Nip01Event(
            pubKey: stalePublicKey,
            kind: 1,
            tags: [
              ['t', 'nostr'],
            ],
            content: 'test content',
            createdAt: 1234567890,
          ),
        );

        expect(signedEvent.pubKey, equals(publicKey));
        expect(signedEvent.id, equals(actuallySigned.id));
        expect(await Bip340EventVerifier().verify(signedEvent), isTrue);
      },
    );

    test(
      'sign keeps the local event when the signer returns no event',
      () async {
        const signature = 'ab12';

        final signer = Nip55EventSigner(
          publicKey: publicKey,
          nip55Signer: _FakeNip55Signer({'signature': signature}),
        );
        addTearDown(signer.dispose);

        final event = Nip01Event(
          pubKey: publicKey,
          kind: 1,
          tags: [],
          content: 'test content',
          createdAt: 1234567890,
        );

        final signedEvent = await signer.sign(event);

        expect(signedEvent.id, equals(event.id));
        expect(signedEvent.sig, equals(signature));
      },
    );
  });
}
