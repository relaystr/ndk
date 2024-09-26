import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'ndk_method_channel.dart';

abstract class NdkPlatform extends PlatformInterface {
  /// Constructs a AmberflutterPlatform.
  NdkPlatform() : super(token: _token);

  static final Object _token = Object();

  static NdkPlatform _instance = MethodChannelDartNdk();

  /// The default instance of [NdkPlatform] to use.
  ///
  /// Defaults to [MethodChannelDartNdk].
  static NdkPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [NdkPlatform] when
  /// they register themselves.
  static set instance(NdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }
}
