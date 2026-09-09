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
      expect(ndk.accounts.getPublicKey(), key0.publicKey);
      expect(ndk.accounts.getLoggedAccount()!.pubkey, key0.publicKey);
      expect(ndk.accounts.hasAccount(key0.publicKey), true);
      ndk.accounts.logout();
      expect(ndk.accounts.isNotLoggedIn, true);
    });

    test('cannot sign', () {
      expect(ndk.accounts.isNotLoggedIn, true);
      ndk.accounts.loginPublicKey(pubkey: key0.publicKey);
      expect(ndk.accounts.isLoggedIn, true);
      expect(ndk.accounts.cannotSign, true);
      expect(ndk.accounts.getPublicKey(), key0.publicKey);
      expect(ndk.accounts.getLoggedAccount()!.pubkey, key0.publicKey);
      expect(ndk.accounts.hasAccount(key0.publicKey), true);
      expect(
        () => ndk.accounts.sign(
          Nip01Event(
            pubKey: key0.publicKey,
            kind: Nip01Event.kTextNodeKind,
            tags: [],
            content: "",
          ),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('loginPrivateKey', () {
      expect(ndk.accounts.isNotLoggedIn, true);
      ndk.accounts.loginPrivateKey(
        pubkey: key0.publicKey,
        privkey: key0.privateKey!,
      );
      expect(ndk.accounts.getLoggedAccount()!.pubkey, key0.publicKey);
      expect(ndk.accounts.isLoggedIn, true);
      expect(ndk.accounts.canSign, true);
      ndk.accounts.logout();
      expect(ndk.accounts.isNotLoggedIn, true);
    });

    test('loginExternalSigner', () {
      expect(ndk.accounts.isNotLoggedIn, true);
      ndk.accounts.loginExternalSigner(
        signer: Bip340EventSigner(
          privateKey: key0.privateKey,
          publicKey: key0.publicKey,
        ),
      );
      expect(ndk.accounts.isLoggedIn, true);
      expect(ndk.accounts.canSign, true);
      ndk.accounts.logout();
      expect(ndk.accounts.isNotLoggedIn, true);
    });

    test('remove account', () {
      expect(ndk.accounts.isNotLoggedIn, true);
      ndk.accounts.loginExternalSigner(
        signer: Bip340EventSigner(
          privateKey: key0.privateKey,
          publicKey: key0.publicKey,
        ),
      );
      expect(ndk.accounts.isLoggedIn, true);
      expect(ndk.accounts.canSign, true);
      ndk.accounts.removeAccount(pubkey: key0.publicKey);
      expect(ndk.accounts.isNotLoggedIn, true);
    });

    test('do not allow duplicated login', () {
      expect(ndk.accounts.isNotLoggedIn, true);
      ndk.accounts.loginPrivateKey(
        pubkey: key0.publicKey,
        privkey: key0.privateKey!,
      );
      expect(ndk.accounts.getLoggedAccount()!.pubkey, key0.publicKey);
      expect(ndk.accounts.isLoggedIn, true);
      expect(ndk.accounts.canSign, true);
      expect(
        () => ndk.accounts.loginPrivateKey(
          pubkey: key0.publicKey,
          privkey: key0.privateKey!,
        ),
        throwsA(isA<Exception>()),
      );
      expect(
        () => ndk.accounts.loginPublicKey(pubkey: key0.publicKey),
        throwsA(isA<Exception>()),
      );
      expect(
        () => ndk.accounts.loginExternalSigner(
          signer: Bip340EventSigner(
            privateKey: key0.privateKey,
            publicKey: key0.publicKey,
          ),
        ),
        throwsA(isA<Exception>()),
      );
      expect(ndk.accounts.getLoggedAccount()!.pubkey, key0.publicKey);
      ndk.accounts.logout();
      expect(ndk.accounts.isNotLoggedIn, true);
    });

    test('switchAccount', () {
      expect(ndk.accounts.isNotLoggedIn, true);
      ndk.accounts.loginPrivateKey(
        pubkey: key0.publicKey,
        privkey: key0.privateKey!,
      );
      expect(ndk.accounts.isLoggedIn, true);
      expect(ndk.accounts.canSign, true);
      expect(ndk.accounts.hasAccount(key0.publicKey), true);
      expect(ndk.accounts.getLoggedAccount()!.pubkey, key0.publicKey);

      ndk.accounts.loginPrivateKey(
        pubkey: key1.publicKey,
        privkey: key1.privateKey!,
      );
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

      expect(
        () => ndk.accounts.switchAccount(pubkey: key0.publicKey),
        throwsA(isA<Exception>()),
      );

      ndk.accounts.logout();
      expect(ndk.accounts.isNotLoggedIn, true);
    });
    test('state Changes Listener', () async {
      final firstAccount = Bip340.generatePrivateKey();
      final secondAccount = Bip340.generatePrivateKey();

      final ndk = Ndk.emptyBootstrapRelaysConfig();

      final stream = ndk.accounts.authStateChanges;

      final expectation = expectLater(
        stream,
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
    });

    test('accountsStream emits on every change', () async {
      final ndk = Ndk.emptyBootstrapRelaysConfig();

      final expectation = expectLater(
        ndk.accounts.accountsStream,
        emitsInOrder([
          isEmpty,
          {key0.publicKey: anything},
          {key0.publicKey: anything, key1.publicKey: anything},
          {key1.publicKey: anything},
          isEmpty,
        ]),
      );

      ndk.accounts.loginPrivateKey(
        pubkey: key0.publicKey,
        privkey: key0.privateKey!,
      );
      ndk.accounts.loginPublicKey(pubkey: key1.publicKey);
      ndk.accounts.removeAccount(pubkey: key0.publicKey);
      ndk.accounts.removeAccount(pubkey: key1.publicKey);

      await expectation;
    });

    test('accountsStream does not emit when nothing changed', () async {
      final ndk = Ndk.emptyBootstrapRelaysConfig();
      final emitted = <Map<String, Account>>[];
      final sub = ndk.accounts.accountsStream.listen(emitted.add);

      ndk.accounts.loginPublicKey(pubkey: key0.publicKey);
      ndk.accounts.removeAccount(pubkey: key1.publicKey);
      ndk.accounts.switchAccount(pubkey: key0.publicKey);

      await Future.delayed(Duration.zero);
      await sub.cancel();

      expect(emitted, hasLength(2));
    });

    test('logout and removeAccount notify in the same order', () async {
      for (final removeLoggedAccount in [
        (Accounts a) => a.logout(),
        (Accounts a) => a.removeAccount(pubkey: key0.publicKey),
      ]) {
        final ndk = Ndk.emptyBootstrapRelaysConfig();
        final order = <String>[];

        ndk.accounts.accountsStream.listen((_) => order.add('accounts'));
        ndk.accounts.authStateChanges.listen((_) => order.add('auth'));

        ndk.accounts.loginPublicKey(pubkey: key0.publicKey);
        await Future.delayed(Duration.zero);
        order.clear();

        removeLoggedAccount(ndk.accounts);
        await Future.delayed(Duration.zero);

        expect(order, ['accounts', 'auth']);
        await ndk.destroy();
      }
    });

    test('emitted accounts are unmodifiable snapshots', () async {
      final ndk = Ndk.emptyBootstrapRelaysConfig();

      ndk.accounts.loginPublicKey(pubkey: key0.publicKey);
      final snapshot = await ndk.accounts.accountsStream.first;

      expect(() => snapshot.clear(), throwsUnsupportedError);
      expect(() => ndk.accounts.accounts.clear(), throwsUnsupportedError);

      ndk.accounts.removeAccount(pubkey: key0.publicKey);
      expect(snapshot, hasLength(1));
      expect(ndk.accounts.accounts, isEmpty);
    });

    test('accounts is the last emitted snapshot', () async {
      final ndk = Ndk.emptyBootstrapRelaysConfig();

      ndk.accounts.loginPublicKey(pubkey: key0.publicKey);
      expect(
          ndk.accounts.accounts, same(await ndk.accounts.accountsStream.first));

      final before = ndk.accounts.accounts;
      ndk.accounts.removeAccount(pubkey: key1.publicKey);
      expect(ndk.accounts.accounts, same(before));

      ndk.accounts.removeAccount(pubkey: key0.publicKey);
      expect(ndk.accounts.accounts, isNot(same(before)));
    });

    test("dispose closes stream", () async {
      final ndk = Ndk.emptyBootstrapRelaysConfig();
      final stream = ndk.accounts.authStateChanges;
      await ndk.destroy();

      await expectLater(stream, emitsDone);
    });
  });
}
