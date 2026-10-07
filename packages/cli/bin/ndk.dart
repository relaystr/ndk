import 'dart:io';

import 'package:ndk_cli/src/accounts/accounts_cli_command.dart';
import 'package:ndk_cli/src/blossom/blossom_cli_command.dart';
import 'package:ndk_cli/src/broadcast/broadcast_cli_command.dart';
import 'package:ndk_cli/src/files/files_cli_command.dart';
import 'package:ndk_cli/src/ndk_cli_app.dart';
import 'package:ndk_cli/src/req_cli_command.dart';
import 'package:ndk_cli/src/wallets/wallets_cli_command.dart';
import 'package:ndk_cli/src/zaps/zaps_cli_command.dart';

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
  exit(exitCode);
}
