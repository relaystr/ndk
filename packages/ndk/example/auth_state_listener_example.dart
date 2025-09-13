import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';

void main() async {
  final ndk = Ndk.emptyBootstrapRelaysConfig();

  ndk.accounts.authStateChanges.listen((account) {
    if (account == null) {
      print('No active user');
    } else {
      print('Active user: ${account.pubkey}');
    }
  });

  final firstAccount = Bip340.generatePrivateKey();
  final secondAccount = Bip340.generatePrivateKey();

  ndk.accounts.loginPrivateKey(
    pubkey: firstAccount.publicKey,
    privkey: firstAccount.privateKey!,
  );

  ndk.accounts.loginPublicKey(pubkey: secondAccount.publicKey);

  ndk.accounts.switchAccount(pubkey: firstAccount.publicKey);

  ndk.accounts.logout();
}
