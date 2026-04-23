import '../../../domain_layer/repositories/event_signer.dart';
import 'bip340_event_signer.dart';

EventSigner defaultEventSignerFactory({
  required String publicKey,
  String? privateKey,
}) {
  return Bip340EventSigner(
    privateKey: privateKey,
    publicKey: publicKey,
  );
}
