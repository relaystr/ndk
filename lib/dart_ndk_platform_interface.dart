import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'dart_ndk_method_channel.dart';

abstract class DartNdkPlatform extends PlatformInterface {
  /// Constructs a AmberflutterPlatform.
  DartNdkPlatform() : super(token: _token);

  static final Object _token = Object();

  static DartNdkPlatform _instance = MethodChannelDartNdk();

  /// The default instance of [DartNdkPlatform] to use.
  ///
  /// Defaults to [MethodChannelDartNdk].
  static DartNdkPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [DartNdkPlatform] when
  /// they register themselves.
  static set instance(DartNdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPublicKey() {
    throw UnimplementedError('getPublicKey() has not been implemented.');
  }

  Future<bool?> verifySignature(String signature, String hash, String pubKey) {
    throw UnimplementedError('verifySignature() has not been implemented.');
  }
}
