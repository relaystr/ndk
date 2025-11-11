import 'dart:developer';

import 'package:ndk/domain_layer/entities/nip_01_event.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';

void main() async {
  final keyPair = Bip340.generatePrivateKey();

  final minedEvent = Nip01Event(
    pubKey: keyPair.publicKey,
    kind: 1,
    tags: [],
    content: 'message',
  ).minePoW(12);

  log(minedEvent.id); // the id will start with "000"

  if (minedEvent.checkPoWDifficulty(10)) {
    log('Event has difficulty >= 10');
  }
}
