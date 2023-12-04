library dart_ndk;

import 'dart_ndk_platform_interface.dart';

export "./relay_manager.dart";

class DartNdk {
  Future<String?> getPublicKey() {
    return DartNdkPlatform.instance.getPublicKey();
  }

  Future<bool?> verifySignature(String signature, String hash, String pubKey) {
    return DartNdkPlatform.instance.verifySignature(signature, hash, pubKey);
  }
}


