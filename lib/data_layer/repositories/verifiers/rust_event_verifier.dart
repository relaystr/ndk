import '../../../domain_layer/entities/nip_01_event.dart';
import '../../../domain_layer/repositories/event_verifier.dart';
import '../../../rust_bridge/api/event_verifier.dart';

class RustEventVerifier implements EventVerifier {
  @override
  Future<bool> verify(Nip01Event event) async {
    return verifySchnorrSignature(
      eventIdHex: event.id,
      pubKeyHex: event.pubKey,
      signatureHex: event.sig,
    );
  }
}
