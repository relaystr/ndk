import 'dart:developer';

import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';

void main() async {
  final keyPair = Bip340.generatePrivateKey();

  final event = Nip01Event(
    pubKey: keyPair.publicKey,
    kind: 1,
    tags: [],
    content: 'message',
  );

  /// your global NDK instance
  final ndk = Ndk.emptyBootstrapRelaysConfig();

  /// pass your event to the proof of work usecase
  final minedEvent =
      await ndk.proofOfWork.minePoW(event: event, targetDifficulty: 10);

  /// the id will start with "000"
  log(minedEvent.id);

  /// check the difficulty
  if (ndk.proofOfWork.checkPoWDifficulty(event: event, targetDifficulty: 10)) {
    log('Event has difficulty >= 10');
  }
}
