import 'package:ndk/domain_layer/repositories/wallets_repo.dart';
import 'package:ndk/ndk.dart';

import 'cli_accounts_store.dart';

abstract class CliCommand {
  String get name;
  String get description;
  String get usage;

  /// Whether persisted accounts should be restored before this command runs.
  ///
  /// Commands that do not use NDK accounts should opt out so a persisted
  /// remote signer cannot introduce unrelated network work at startup.
  bool get restoreAccountsOnStartup => true;

  Future<int> run(
    List<String> args,
    Ndk ndk,
    WalletsRepo walletsRepo,
    CliAccountsStore accountsStore,
  );
}
