import 'dart:io';

import 'package:ndk/src/cli/accounts/accounts_cli_command.dart';
import 'package:ndk/src/cli/blossom/blossom_cli_command.dart';
import 'package:ndk/src/cli/broadcast/broadcast_cli_command.dart';
import 'package:ndk/src/cli/files/files_cli_command.dart';
import 'package:ndk/src/cli/ndk_cli_app.dart';
import 'package:ndk/src/cli/req_cli_command.dart';
import 'package:ndk/src/cli/wallets/wallets_cli_command.dart';
import 'package:ndk/src/cli/zaps/zaps_cli_command.dart';

Future<void> main(List<String> args) async {
  final app = NdkCliApp(
    appName: 'ndk',
    description: 'Nostr Development Kit command line interface',
    commands: [
      ReqCliCommand(),
      BroadcastCliCommand(),
      AccountsCliCommand(),
      WalletsCliCommand(),
      ZapsCliCommand(),
      FilesCliCommand(),
      BlossomCliCommand(),
    ],
  );

  final exitCode = await app.run(args);
  if (exitCode != 0) {
    exit(exitCode);
  }
}
