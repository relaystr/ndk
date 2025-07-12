import 'package:nip07_event_signer/nip07_event_signer.dart';

void main() async {
  await Nip07EventSigner().getPublicKeyAsync();
}
