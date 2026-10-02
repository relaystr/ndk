// ignore_for_file: constant_identifier_names

class CashuConfig {
  static const String NUT_VERSION = 'v1';
  static const String DOMAIN_SEPARATOR_HashToCurve =
      'Secp256k1_HashToCurve_Cashu_';

  static const Duration FUNDING_CHECK_INTERVAL = Duration(seconds: 10);
  static const Duration SPEND_CHECK_INTERVAL = Duration(seconds: 15);

  /// How long [Cashu.restore] waits for a pending quote to be paid before
  /// moving on (mints that auto-pay invoices, like dev mints, may take a few
  /// seconds to mark the quote as paid).
  static const Duration QUOTE_PAY_TIMEOUT = Duration(seconds: 45);

  /// Interval between paid-state polls while waiting for a quote in
  /// [Cashu.restore].
  static const Duration QUOTE_PAY_RETRY_INTERVAL = Duration(seconds: 3);

  /// Timeout for network requests to mint - fails fast if mint is offline
  static const Duration NETWORK_TIMEOUT = Duration(seconds: 10);

  /// Default cap for [Cashu._findQuoteKeyCounter]'s counter scan when the
  /// persisted quote-key counter slot is unavailable. Each scanned counter
  /// derives a keypair (a handful of EC point operations), so a very large
  /// limit can turn an automatic, unattended recovery (e.g. on startup) into a
  /// multi-minute CPU-bound scan. Callers recovering an intentionally
  /// high-counter quote can pass a larger `maxScan` explicitly.
  static const int defaultQuoteKeyScanLimit = 1000;
}
