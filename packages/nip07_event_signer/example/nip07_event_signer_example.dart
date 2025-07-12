import 'package:ndk/ndk.dart';

/// import web signer package
import 'package:nip07_event_signer/nip07_event_signer.dart';

void main() async {
  /// create ndk obj
  final ndk = Ndk.defaultConfig();

  /// create web signer
  final webSigner = Nip07EventSigner();

  /// on web you need to call this first!
  await webSigner.getPublicKeyAsync();

  /// login with the web signer
  ndk.accounts.loginExternalSigner(signer: webSigner);
}
