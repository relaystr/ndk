import 'dart:async';

import 'package:test/test.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';

void main() {
  test('Auth State Listener', () async {
    final firstAccount = Bip340.generatePrivateKey();
    final secondAccount = Bip340.generatePrivateKey();

    final ndk = Ndk.emptyBootstrapRelaysConfig();

    final streamController = StreamController<Account?>();
    ndk.accounts.authStateChanges.listen((account) {
      streamController.add(account);
    });

    final expectation = expectLater(
      streamController.stream,
      emitsInOrder([
        predicate<Account?>((a) => a?.pubkey == firstAccount.publicKey),
        predicate<Account?>((a) => a?.pubkey == secondAccount.publicKey),
        predicate<Account?>((a) => a?.pubkey == firstAccount.publicKey),
        predicate<Account?>((a) => a?.pubkey == null),
      ]),
    );

    ndk.accounts.loginPrivateKey(
      pubkey: firstAccount.publicKey,
      privkey: firstAccount.privateKey!,
    );

    ndk.accounts.loginPublicKey(pubkey: secondAccount.publicKey);

    ndk.accounts.switchAccount(pubkey: firstAccount.publicKey);

    ndk.accounts.logout();

    await expectation;
    await streamController.close();
  });
}
