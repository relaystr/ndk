import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';

import 'web_event_signer_web.dart';

/// Web alias of [NdkEventSigner]: fast [WebEventSigner] via JS interop.
typedef NdkEventSigner = WebEventSigner;

/// Web factory: produces [WebEventSigner] instances using @noble/curves.
class NdkEventSignerFactory implements LocalEventSignerFactory {
  const NdkEventSignerFactory();

  @override
  EventSigner create({String? privateKey, String? publicKey}) {
    final derivedPublicKey =
        publicKey ?? (privateKey != null ? derivePublicKey(privateKey) : null);

    if (derivedPublicKey == null) {
      throw ArgumentError('Either publicKey or privateKey must be provided');
    }

    return WebEventSigner(
      privateKey: privateKey,
      publicKey: derivedPublicKey,
    );
  }

  @override
  String derivePublicKey(String privateKey) => Bip340.getPublicKey(privateKey);

  @override
  (String, String) generateKeyPair() {
    final keyPair = Bip340.generatePrivateKey();
    return (keyPair.privateKey!, keyPair.publicKey);
  }

  @override
  EventSigner createWithNewKeyPair() {
    final (privateKey, publicKey) = generateKeyPair();
    return create(privateKey: privateKey, publicKey: publicKey);
  }
}
