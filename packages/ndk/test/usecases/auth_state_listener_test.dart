import 'dart:async';

import 'package:test/test.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

void main() {
  group('Auth State Listener', () {
    late Ndk ndk;
    late KeyPair key1;
    late KeyPair key2;

    setUp(() {
      ndk = Ndk.defaultConfig();
      key1 = Bip340.generatePrivateKey();
      key2 = Bip340.generatePrivateKey();
    });

    tearDown(() async {
      ndk.accounts.dispose();
      await ndk.destroy();
    });

    test('initial auth state should be null', () {
      final currentAccount = ndk.accounts.getLoggedAccount();
      expect(currentAccount, isNull);
    });

    test('auth state changes when logging in with private key', () async {
      final accounts = <Account?>[];
      final subscription = ndk.accounts.authStateChanges.listen(accounts.add);

      ndk.accounts.loginPrivateKey(
        pubkey: key1.publicKey,
        privkey: key1.privateKey!,
      );

      await Future.delayed(Duration(milliseconds: 100));

      expect(accounts.length, 1);
      expect(accounts.last, isNotNull);
      expect(accounts.last?.pubkey, key1.publicKey);
      expect(accounts.last?.type, AccountType.privateKey);

      await subscription.cancel();
    });

    test('auth state changes when logging in with public key', () async {
      final accounts = <Account?>[];
      final subscription = ndk.accounts.authStateChanges.listen(accounts.add);

      ndk.accounts.loginPublicKey(pubkey: key1.publicKey);

      await Future.delayed(Duration(milliseconds: 100));

      expect(accounts.length, 1);
      expect(accounts.last, isNotNull);
      expect(accounts.last?.pubkey, key1.publicKey);
      expect(accounts.last?.type, AccountType.publicKey);

      await subscription.cancel();
    });

    test('auth state changes to null when logging out', () async {
      final accounts = <Account?>[];

      ndk.accounts.loginPrivateKey(
        pubkey: key1.publicKey,
        privkey: key1.privateKey!,
      );

      final subscription = ndk.accounts.authStateChanges.listen(accounts.add);

      ndk.accounts.logout();

      await Future.delayed(Duration(milliseconds: 100));

      expect(accounts.length, 1);
      expect(accounts.last, isNull);

      await subscription.cancel();
    });

    test('auth state changes when switching accounts', () async {
      final accounts = <Account?>[];

      ndk.accounts.loginPrivateKey(
        pubkey: key1.publicKey,
        privkey: key1.privateKey!,
      );

      ndk.accounts.loginPublicKey(pubkey: key2.publicKey);

      final subscription = ndk.accounts.authStateChanges.listen(accounts.add);

      ndk.accounts.switchAccount(pubkey: key2.publicKey);

      await Future.delayed(Duration(milliseconds: 100));

      expect(accounts.length, 1);
      expect(accounts.last, isNotNull);
      expect(accounts.last?.pubkey, key2.publicKey);

      await subscription.cancel();
    });

    test('multiple listeners receive auth state changes', () async {
      final accounts1 = <Account?>[];
      final accounts2 = <Account?>[];

      final subscription1 = ndk.accounts.authStateChanges.listen(accounts1.add);
      final subscription2 = ndk.accounts.authStateChanges.listen(accounts2.add);

      ndk.accounts.loginPrivateKey(
        pubkey: key1.publicKey,
        privkey: key1.privateKey!,
      );

      await Future.delayed(Duration(milliseconds: 100));

      expect(accounts1.length, 1);
      expect(accounts2.length, 1);
      expect(accounts1.last, isNotNull);
      expect(accounts2.last, isNotNull);
      expect(accounts1.last?.pubkey, key1.publicKey);
      expect(accounts2.last?.pubkey, key1.publicKey);

      await subscription1.cancel();
      await subscription2.cancel();
    });

    test('auth state stream is broadcast stream', () {
      expect(ndk.accounts.authStateChanges.isBroadcast, true);
    });

    test('sequence of login, logout, login emits correct states', () async {
      final accounts = <Account?>[];
      final subscription = ndk.accounts.authStateChanges.listen(accounts.add);

      ndk.accounts.loginPrivateKey(
        pubkey: key1.publicKey,
        privkey: key1.privateKey!,
      );

      await Future.delayed(Duration(milliseconds: 50));

      ndk.accounts.logout();

      await Future.delayed(Duration(milliseconds: 50));

      ndk.accounts.loginPublicKey(pubkey: key2.publicKey);

      await Future.delayed(Duration(milliseconds: 50));

      expect(accounts.length, 3);
      expect(accounts[0], isNotNull);
      expect(accounts[0]?.pubkey, key1.publicKey);
      expect(accounts[1], isNull);
      expect(accounts[2], isNotNull);
      expect(accounts[2]?.pubkey, key2.publicKey);

      await subscription.cancel();
    });
  });
}
