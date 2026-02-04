// ignore_for_file: constant_identifier_names

class CashuConfig {
  static const String NUT_VERSION = 'v1';
  static const String DOMAIN_SEPARATOR_HashToCurve =
      'Secp256k1_HashToCurve_Cashu_';

  static const Duration FUNDING_CHECK_INTERVAL = Duration(seconds: 2);
  static const Duration SPEND_CHECK_INTERVAL = Duration(seconds: 5);

  /// Timeout for network requests to mint - fails fast if mint is offline
  static const Duration NETWORK_TIMEOUT = Duration(seconds: 10);
}
