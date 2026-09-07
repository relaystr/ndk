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

  group('RelayAuth identity', () {
    test('never is a single value', () {
      expect(const RelayAuth.never(), same(const RelayAuth.never()));
      expect(const RelayAuth.never().account, isNull);
    });

    test('two policies for the same pubkey are equal', () {
      expect(
          RelayAuth.allow(_signable(keyA)), RelayAuth.allow(_signable(keyA)));
      expect(
        RelayAuth.allow(_signable(keyA)).hashCode,
        RelayAuth.allow(_signable(keyA)).hashCode,
      );
    });

    test('allow and require are never interchangeable', () {
      final account = _signable(keyA);

      expect(RelayAuth.allow(account), isNot(RelayAuth.require(account)));
      expect(RelayAuth.allow(account), isNot(const RelayAuth.never()));
    });

    test('two accounts give two policies', () {
      expect(
        RelayAuth.allow(_signable(keyA)),
        isNot(RelayAuth.allow(_signable(keyB))),
      );
    });

    test('canonical is what the policy prints as', () {
      final account = _signable(keyA);

      expect(const RelayAuth.never().canonical, 'never');
      expect(RelayAuth.allow(account).canonical, 'allow:${keyA.publicKey}');
      expect(RelayAuth.require(account).canonical, 'require:${keyA.publicKey}');
      expect(
        RelayAuth.require(account).toString(),
        RelayAuth.require(account).canonical,
      );
    });
  });

  group('RelayAuth.keyFor', () {
    test('an absent policy stays anonymous', () {
      expect(RelayAuth.keyFor(url, null), RelayConnectionKey.anonymous(url));
    });

    test('never and allow start anonymous', () {
      expect(
        RelayAuth.keyFor(url, const RelayAuth.never()),
        RelayConnectionKey.anonymous(url),
      );
      expect(
        RelayAuth.keyFor(url, RelayAuth.allow(_signable(keyA))),
        RelayConnectionKey.anonymous(url),
      );
    });

    test('require binds the connection from the start', () {
      expect(
        RelayAuth.keyFor(url, RelayAuth.require(_signable(keyA))),
        RelayConnectionKey.authenticated(url, keyA.publicKey),
      );
    });

    test('require without a signer has no connection to use', () {
      expect(
          RelayAuth.keyFor(url, RelayAuth.require(_watchOnly(keyA))), isNull);
    });
  });

  group('RelayAuth.fromDeprecatedAccounts', () {
    test('no account keeps the historical default', () {
      expect(RelayAuth.fromDeprecatedAccounts(null), isNull);
      expect(RelayAuth.fromDeprecatedAccounts([]), isNull);
    });

    test('the first signable account is the one that is used', () {
      final signable = _signable(keyB);

      expect(
        RelayAuth.fromDeprecatedAccounts([_watchOnly(keyA), signable]),
        RelayAuth.allow(signable),
      );
    });

    test('a list where nobody can sign never authenticates', () {
      expect(
        RelayAuth.fromDeprecatedAccounts([_watchOnly(keyA), _watchOnly(keyB)]),
        const RelayAuth.never(),
      );
    });
  });
}
