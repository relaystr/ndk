import 'dart:async';

import '../../../domain_layer/entities/nip_01_event.dart';
import '../../../domain_layer/repositories/event_verifier.dart';
import '../../../rust_bridge/api/event_verifier.dart';
import '../../../rust_bridge/frb_generated.dart';

class RustEventVerifier implements EventVerifier {
  Completer<bool> isInitialized = Completer<bool>();

  RustEventVerifier() {
    init();
  }

  Future<bool> init() async {
    await RustLib.init();
    isInitialized.complete(true);
    return true;
  }

  @override
  Future<bool> verify(Nip01Event event) async {
    await isInitialized.future;

    return verifySchnorrSignature(
      eventIdHex: event.id,
      pubKeyHex: event.pubKey,
      signatureHex: event.sig,
    );
  }
}
