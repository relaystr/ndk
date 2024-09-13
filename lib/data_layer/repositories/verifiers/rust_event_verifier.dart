import 'dart:async';

import '../../../domain_layer/entities/nip_01_event.dart';
import '../../../domain_layer/repositories/event_verifier.dart';
import '../../../rust_bridge/api/event_verifier.dart';
import '../../../rust_bridge/frb_generated.dart';

class RustEventVerifier implements EventVerifier {
  final Completer<bool> _isInitialized = Completer<bool>();

  RustEventVerifier() {
    _init();
  }

  Future<bool> _init() async {
    await RustLib.init();
    _isInitialized.complete(true);
    return true;
  }

  @override
  Future<bool> verify(Nip01Event event) async {
    await _isInitialized.future;

    return verifyNostrEvent(
      eventIdHex: event.id,
      pubKeyHex: event.pubKey,
      createdAt: BigInt.from(event.createdAt),
      kind: event.kind,
      tags: event.tags,
      content: event.content,
      signatureHex: event.sig,
    );
  }
}
