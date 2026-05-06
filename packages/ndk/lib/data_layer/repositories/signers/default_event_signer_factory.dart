import '../../../domain_layer/repositories/event_signer.dart';
import '../../../domain_layer/repositories/nip44_cryptography.dart';
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

EventSignerFactory buildDefaultEventSignerFactory({
  required Nip44Cryptography nip44Cryptography,
}) {
  return ({required String publicKey, String? privateKey}) {
    return Bip340EventSigner(
      privateKey: privateKey,
      publicKey: publicKey,
      nip44Cryptography: nip44Cryptography,
    );
  };
}
