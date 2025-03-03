// ignore_for_file: constant_identifier_names

/// defaults
class BroadcastDefaults {
  /// the max amout of inbox relays to push a event per pubkey
  static const int MAX_INBOX_RELAYS_TO_BROADCAST = 5;
  static const double CONSIDER_DONE_PERCENT = 1.0;
  static const Duration TIMEOUT = Duration(seconds: 10);
}
