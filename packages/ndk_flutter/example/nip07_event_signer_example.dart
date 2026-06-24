// ignore_for_file: avoid_print

import 'package:ndk_flutter/ndk_flutter.dart';

void main() async {
  final signer = Nip07EventSigner();
  if (!signer.canSign()) {
    return;
  }

  final pubkey = await signer.getPublicKeyAsync();
  print(pubkey);
}
