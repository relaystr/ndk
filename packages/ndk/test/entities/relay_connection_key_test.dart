import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:test/test.dart';

void main() {
  final pubkeyA = Bip340.generatePrivateKey().publicKey;
  final pubkeyB = Bip340.generatePrivateKey().publicKey;

  group('RelayConnectionKey normalization', () {
    test('equivalent urls produce the same key', () {
      final variants = [
        'wss://relay.example.com',
        'wss://relay.example.com/',
        'wss://Relay.Example.com',
        'wss://relay.example.com:443',
        '  wss://relay.example.com  ',
        'wss:///relay.example.com',
      ];

      final keys = variants.map(RelayConnectionKey.anonymous).toSet();

      expect(keys, hasLength(1));
      expect(keys.single.url, 'wss://relay.example.com');
    });

    test('different relays produce different keys', () {
      expect(
        RelayConnectionKey.anonymous('wss://a.example.com'),
        isNot(RelayConnectionKey.anonymous('wss://b.example.com')),
      );
    });

    test('an unparsable url is kept as given instead of throwing', () {
      final key = RelayConnectionKey.anonymous('  not a url  ');

      expect(key.url, 'not a url');
      expect(key.isAnonymous, isTrue);
    });
  });

  group('RelayConnectionKey identity', () {
    test('anonymous and authenticated keys differ for the same relay', () {
      final anonymous = RelayConnectionKey.anonymous('wss://relay.example.com');
      final authenticated = RelayConnectionKey.authenticated(
        'wss://relay.example.com',
        pubkeyA,
      );

      expect(anonymous, isNot(authenticated));
      expect(anonymous.isAnonymous, isTrue);
      expect(authenticated.isAnonymous, isFalse);
      expect(authenticated.pubkey, pubkeyA);
    });

    test('two accounts on the same relay produce different keys', () {
      expect(
        RelayConnectionKey.authenticated('wss://relay.example.com', pubkeyA),
        isNot(
          RelayConnectionKey.authenticated('wss://relay.example.com', pubkeyB),
        ),
      );
    });

    test('pubkey case does not create a second connection', () {
      final upper = RelayConnectionKey.authenticated(
        'wss://relay.example.com',
        pubkeyA.toUpperCase(),
      );
      final lower = RelayConnectionKey.authenticated(
        'wss://relay.example.com',
        pubkeyA,
      );

      expect(upper, lower);
      expect(upper.hashCode, lower.hashCode);
      expect(upper.pubkey, pubkeyA);
    });

    test('a pubkey that is not 64 hex characters is rejected', () {
      expect(
        () =>
            RelayConnectionKey.authenticated('wss://relay.example.com', 'abc'),
        throwsArgumentError,
      );
      expect(
        () => RelayConnectionKey.authenticated(
          'wss://relay.example.com',
          'npub1${'0' * 59}',
        ),
        throwsArgumentError,
      );
    });
  });

  group('RelayConnectionKey as a map key', () {
    test('lookup succeeds across url spellings', () {
      final relays = <RelayConnectionKey, String>{
        RelayConnectionKey.anonymous('wss://relay.example.com'): 'anonymous',
        RelayConnectionKey.authenticated('wss://relay.example.com', pubkeyA):
            'authenticated',
      };

      expect(
        relays[RelayConnectionKey.anonymous('wss://relay.example.com/')],
        'anonymous',
      );
      expect(
        relays[RelayConnectionKey.authenticated(
          'wss://RELAY.example.com',
          pubkeyA.toUpperCase(),
        )],
        'authenticated',
      );
      expect(relays, hasLength(2));
    });
  });

  group('RelayConnectionKey canonical form', () {
    test('marks the anonymous connection', () {
      expect(
        RelayConnectionKey.anonymous('wss://relay.example.com/').canonical,
        'wss://relay.example.com|anon',
      );
    });

    test('carries the pubkey when authenticated', () {
      expect(
        RelayConnectionKey.authenticated(
          'wss://relay.example.com',
          pubkeyA,
        ).canonical,
        'wss://relay.example.com|$pubkeyA',
      );
    });

    test('is what the key prints as', () {
      final key = RelayConnectionKey.authenticated(
        'wss://relay.example.com',
        pubkeyA,
      );

      expect(key.toString(), key.canonical);
    });

    test('the anonymous marker cannot be produced by a real pubkey', () {
      expect(
        () => RelayConnectionKey.authenticated(
          'wss://relay.example.com',
          RelayConnectionKey.anonymousMarker,
        ),
        throwsArgumentError,
      );
    });
  });
}
