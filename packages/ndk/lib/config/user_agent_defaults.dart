// ignore_for_file: constant_identifier_names

import '../src/version.dart';

class UserAgentDefaults {
  /// NDK's User-Agent, opt in via NdkConfig.userAgent
  static const String DEFAULT_USER_AGENT = "dart-NDK/$packageVersion";
}
