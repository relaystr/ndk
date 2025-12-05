import 'dart:developer';

import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';

void main() async {
  final keyPair = Bip340.generatePrivateKey();

  final event = Nip01EventService.createEventCalculateId(
    pubKey: keyPair.publicKey,
    kind: 1,
    tags: [],
    content: 'message',
  );

  final minedEvent =
      await ProofOfWork.minePoW(event: event, targetDifficulty: 10);

  log(minedEvent.id); // the id will start with "000"

  if (ProofOfWork.checkPoWDifficulty(event: event, targetDifficulty: 10)) {
    log('Event has difficulty >= 10');
  }
}
