import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

Account _signable(KeyPair keyPair) => Account(
      type: AccountType.privateKey,
      pubkey: keyPair.publicKey,
      signer: Bip340EventSigner(
        privateKey: keyPair.privateKey,
        publicKey: keyPair.publicKey,
      ),
    );

Account _watchOnly(KeyPair keyPair) => Account(
      type: AccountType.publicKey,
      pubkey: keyPair.publicKey,
      signer: Bip340EventSigner(privateKey: null, publicKey: keyPair.publicKey),
    );

void main() {
  final keyA = Bip340.generatePrivateKey();
  final keyB = Bip340.generatePrivateKey();

  const url = 'wss://relay.example.com';

  group('AuthPolicy identity', () {
    test('never is a single value', () {
      expect(const AuthPolicy.never(), same(const AuthPolicy.never()));
      expect(const AuthPolicy.never().account, isNull);
    });

    test('two policies for the same pubkey are equal', () {
      expect(
          AuthPolicy.allow(_signable(keyA)), AuthPolicy.allow(_signable(keyA)));
      expect(
        AuthPolicy.allow(_signable(keyA)).hashCode,
        AuthPolicy.allow(_signable(keyA)).hashCode,
      );
    });

    test('allow and require are never interchangeable', () {
      final account = _signable(keyA);

      expect(AuthPolicy.allow(account), isNot(AuthPolicy.require(account)));
      expect(AuthPolicy.allow(account), isNot(const AuthPolicy.never()));
    });

    test('two accounts give two policies', () {
      expect(
        AuthPolicy.allow(_signable(keyA)),
        isNot(AuthPolicy.allow(_signable(keyB))),
      );
    });

    test('canonical is what the policy prints as', () {
      final account = _signable(keyA);

      expect(const AuthPolicy.never().canonical, 'never');
      expect(AuthPolicy.allow(account).canonical, 'allow:${keyA.publicKey}');
      expect(
          AuthPolicy.require(account).canonical, 'require:${keyA.publicKey}');
      expect(
        AuthPolicy.require(account).toString(),
        AuthPolicy.require(account).canonical,
      );
    });
  });

  group('AuthPolicy.keyFor', () {
    test('an absent policy stays anonymous', () {
      expect(RelayConnectionKey.forAuth(url, null),
          RelayConnectionKey.anonymous(url));
    });

    test('never and allow start anonymous', () {
      expect(
        RelayConnectionKey.forAuth(url, const AuthPolicy.never()),
        RelayConnectionKey.anonymous(url),
      );
      expect(
        RelayConnectionKey.forAuth(url, AuthPolicy.allow(_signable(keyA))),
        RelayConnectionKey.anonymous(url),
      );
    });

    test('require binds the connection from the start', () {
      expect(
        RelayConnectionKey.forAuth(url, AuthPolicy.require(_signable(keyA))),
        RelayConnectionKey.authenticated(url, keyA.publicKey),
      );
    });

    test('require without a signer has no connection to use', () {
      expect(
          RelayConnectionKey.forAuth(url, AuthPolicy.require(_watchOnly(keyA))),
          isNull);
    });
  });

  group('AuthPolicy.fromDeprecatedAccounts', () {
    test('no account keeps the historical default', () {
      expect(AuthPolicy.fromDeprecatedAccounts(null), isNull);
      expect(AuthPolicy.fromDeprecatedAccounts([]), isNull);
    });

    test('the first signable account is the one that is used', () {
      final signable = _signable(keyB);

      expect(
        AuthPolicy.fromDeprecatedAccounts([_watchOnly(keyA), signable]),
        AuthPolicy.allow(signable),
      );
    });

    test('a list where nobody can sign never authenticates', () {
      expect(
        AuthPolicy.fromDeprecatedAccounts([_watchOnly(keyA), _watchOnly(keyB)]),
        const AuthPolicy.never(),
      );
    });
  });
}
