import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hex/hex.dart';

import 'ndk_platform_interface.dart';

/// An implementation of [NdkPlatform] that uses method channels.
class MethodChannelDartNdk extends NdkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('ndk');

  Future<String?> getPublicKey() async {
    final pk = await methodChannel.invokeMethod<String>('get_public_key');
    return pk;
  }

  Future<bool?> verifySignature(
      String signature, String hash, String pubKey) async {
    final arguments = {
      "signature": HEX.decode(signature),
      "hash": HEX.decode(hash),
      "pubKey": HEX.decode(pubKey)
    };
    return await methodChannel.invokeMethod<bool>(
      'verifySignature',
      arguments,
    );
  }
}
