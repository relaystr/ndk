import 'package:test/test.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

void main() async {
  group('accounts', () {
    KeyPair key0 = Bip340.generatePrivateKey();
    KeyPair key1 = Bip340.generatePrivateKey();

    late Ndk ndk;

    setUp(() async {
      ndk = Ndk.defaultConfig();
    });

    tearDown(() async {
      await ndk.destroy();
    });

    test('loginPublicKey', () {
      expect(ndk.accounts.isNotLoggedIn, true);
      ndk.accounts.loginPublicKey(pubkey: key0.publicKey);
      expect(ndk.accounts.isLoggedIn, true);
      expect(ndk.accounts.cannotSign, true);
      expect(ndk.accounts.hasAccount(key0.publicKey), true);
      ndk.accounts.logout();
      expect(ndk.accounts.isNotLoggedIn, true);
    });

    test('loginPrivateKey', () {
      expect(ndk.accounts.isNotLoggedIn, true);
      ndk.accounts.loginPrivateKey(pubkey: key0.publicKey, privkey: key0.privateKey!);
      expect(ndk.accounts.getLoggedAccount()!.pubkey, key0.publicKey);
      expect(ndk.accounts.isLoggedIn, true);
      expect(ndk.accounts.canSign, true);
      ndk.accounts.logout();
      expect(ndk.accounts.isNotLoggedIn, true);
    });

    test('loginExternalSigner', () {
      expect(ndk.accounts.isNotLoggedIn, true);
      ndk.accounts.loginExternalSigner(signer: Bip340EventSigner(privateKey: key0.privateKey, publicKey: key0.publicKey));
      expect(ndk.accounts.isLoggedIn, true);
      expect(ndk.accounts.canSign, true);
      ndk.accounts.logout();
      expect(ndk.accounts.isNotLoggedIn, true);
    });

    test('remove account', () {
      expect(ndk.accounts.isNotLoggedIn, true);
      ndk.accounts.loginExternalSigner(signer: Bip340EventSigner(privateKey: key0.privateKey, publicKey: key0.publicKey));
      expect(ndk.accounts.isLoggedIn, true);
      expect(ndk.accounts.canSign, true);
      ndk.accounts.removeAccount(pubkey: key0.publicKey);
      expect(ndk.accounts.isNotLoggedIn, true);
    });

    test('do not allow duplicated login', () {
      expect(ndk.accounts.isNotLoggedIn, true);
      ndk.accounts.loginPrivateKey(pubkey: key0.publicKey, privkey: key0.privateKey!);
      expect(ndk.accounts.getLoggedAccount()!.pubkey, key0.publicKey);
      expect(ndk.accounts.isLoggedIn, true);
      expect(ndk.accounts.canSign, true);
      expect(() => ndk.accounts.loginPrivateKey(pubkey: key0.publicKey, privkey: key0.privateKey!), throwsA(isA<Exception>()));
      expect(ndk.accounts.getLoggedAccount()!.pubkey, key0.publicKey);
      ndk.accounts.logout();
      expect(ndk.accounts.isNotLoggedIn, true);
    });

    test('switchAccount', () {
      expect(ndk.accounts.isNotLoggedIn, true);
      ndk.accounts.loginPrivateKey(pubkey: key0.publicKey, privkey: key0.privateKey!);
      expect(ndk.accounts.isLoggedIn, true);
      expect(ndk.accounts.canSign, true);
      expect(ndk.accounts.hasAccount(key0.publicKey), true);
      expect(ndk.accounts.getLoggedAccount()!.pubkey, key0.publicKey);

      ndk.accounts.loginPrivateKey(pubkey: key1.publicKey, privkey: key1.privateKey!);
      expect(ndk.accounts.hasAccount(key1.publicKey), true);
      expect(ndk.accounts.getLoggedAccount()!.pubkey, key1.publicKey);

      ndk.accounts.switchAccount(pubkey: key0.publicKey);
      expect(ndk.accounts.hasAccount(key0.publicKey), true);
      expect(ndk.accounts.hasAccount(key1.publicKey), true);
      expect(ndk.accounts.getLoggedAccount()!.pubkey, key0.publicKey);

      ndk.accounts.logout();
      expect(ndk.accounts.hasAccount(key0.publicKey), false);
      expect(ndk.accounts.hasAccount(key1.publicKey), true);
      expect(ndk.accounts.isNotLoggedIn, true);
      expect(ndk.accounts.cannotSign, true);
      expect(ndk.accounts.getLoggedAccount(), isNull);

      ndk.accounts.switchAccount(pubkey: key1.publicKey);
      expect(ndk.accounts.hasAccount(key1.publicKey), true);
      expect(ndk.accounts.getLoggedAccount()!.pubkey, key1.publicKey);
      expect(ndk.accounts.isLoggedIn, true);
      expect(ndk.accounts.canSign, true);

      ndk.accounts.logout();
      expect(ndk.accounts.isNotLoggedIn, true);
    });
  });
}
