import 'dart:io';

import 'package:ndk/src/cli/ndk_cli_app.dart';
import 'package:ndk/src/cli/wallets/wallets_cli_command.dart';
import 'package:ndk/src/cli/req_cli_command.dart';

Future<void> main(List<String> args) async {
  final app = NdkCliApp(
    appName: 'ndk',
    description: 'Nostr Development Kit command line interface',
    commands: [
      WalletsCliCommand(),
      ReqCliCommand(),
    ],
  );

  final exitCode = await app.run(args);
  if (exitCode != 0) {
    exit(exitCode);
  }
}
