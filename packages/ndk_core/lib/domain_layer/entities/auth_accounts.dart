import 'account.dart';

/// The accounts relays may be authenticated as (NIP-42).
abstract interface class AuthAccounts {
  /// registered accounts, by pubkey
  Map<String, Account> get accounts;

  Account? getLoggedAccount();
}
