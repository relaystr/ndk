import 'package:ndk_cli/src/wallets/wallets_cli_command.dart';
import 'package:test/test.dart';

void main() {
  test('wallet commands do not restore unrelated remote signer accounts', () {
    expect(WalletsCliCommand().restoreAccountsOnStartup, isFalse);
  });
}
