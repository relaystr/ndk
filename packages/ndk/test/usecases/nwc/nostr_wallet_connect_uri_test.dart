import 'package:ndk/domain_layer/usecases/nwc/nostr_wallet_connect_uri.dart';
import 'package:test/test.dart';

void main() {
  group('NostrWalletConnectUri', () {
    test('should parse a valid connection URI with single relay', () {
      final uri =
          'nostr+walletconnect://pubkey123?relay=wss://relay.example.com&secret=secret123&lud16=lud16value';
      final nostrUri = NostrWalletConnectUri.parseConnectionUri(uri);

      expect(nostrUri.walletPubkey, equals('pubkey123'));
      expect(nostrUri.relays, equals(['wss://relay.example.com']));
      expect(
          nostrUri.relay, equals('wss://relay.example.com')); // Legacy getter
      expect(nostrUri.secret, equals('secret123'));
      expect(nostrUri.lud16, equals('lud16value'));
    });

    test('should parse a connection URI with comma-separated relays', () {
      final uri =
          'nostr+walletconnect://pubkey123?relays=wss://relay1.example.com,wss://relay2.example.com,wss://relay3.example.com&secret=secret123';
      final nostrUri = NostrWalletConnectUri.parseConnectionUri(uri);

      expect(nostrUri.walletPubkey, equals('pubkey123'));
      expect(
          nostrUri.relays,
          equals([
            'wss://relay1.example.com',
            'wss://relay2.example.com',
            'wss://relay3.example.com'
          ]));
      expect(nostrUri.secret, equals('secret123'));
    });

    test('should parse a connection URI with mixed relay parameters', () {
      final uri =
          'nostr+walletconnect://pubkey123?relay=wss://relay1.example.com&relays=wss://relay2.example.com,wss://relay3.example.com&secret=secret123';
      final nostrUri = NostrWalletConnectUri.parseConnectionUri(uri);

      expect(nostrUri.walletPubkey, equals('pubkey123'));
      expect(
          nostrUri.relays,
          equals([
            'wss://relay1.example.com',
            'wss://relay2.example.com',
            'wss://relay3.example.com'
          ]));
      expect(nostrUri.secret, equals('secret123'));
    });

    test('should deduplicate relays when parsing', () {
      final uri =
          'nostr+walletconnect://pubkey123?relay=wss://relay1.example.com&relays=wss://relay1.example.com,wss://relay2.example.com&secret=secret123';
      final nostrUri = NostrWalletConnectUri.parseConnectionUri(uri);

      expect(nostrUri.walletPubkey, equals('pubkey123'));
      expect(nostrUri.relays,
          equals(['wss://relay1.example.com', 'wss://relay2.example.com']));
      expect(nostrUri.secret, equals('secret123'));
    });

    test('should throw an exception for missing required fields', () {
      final uri = 'nostr+walletconnect://pubkey123?relays=wss://relay.example.com';

      expect(
        () => NostrWalletConnectUri.parseConnectionUri(uri),
        throwsA(isA<Exception>()),
      );
    });

    test('should throw an exception when no relays are provided', () {
      final uri = 'nostr+walletconnect://pubkey123?secret=secret123';

      expect(
        () => NostrWalletConnectUri.parseConnectionUri(uri),
        throwsA(predicate(
            (e) => e.toString().contains('At least one relay is required'))),
      );
    });

    test('should correctly compare two equal instances with single relay', () {
      final uri1 = NostrWalletConnectUri(
        walletPubkey: 'pubkey123',
        relays: ['wss://relay.example.com'],
        secret: 'secret123',
        lud16: 'lud16value',
      );

      final uri2 = NostrWalletConnectUri(
        walletPubkey: 'pubkey123',
        relays: ['wss://relay.example.com'],
        secret: 'secret123',
        lud16: 'lud16value',
      );

      expect(uri1, equals(uri2));
    });

    test('should correctly compare two equal instances with multiple relays',
        () {
      final uri1 = NostrWalletConnectUri(
        walletPubkey: 'pubkey123',
        relays: ['wss://relay1.example.com', 'wss://relay2.example.com'],
        secret: 'secret123',
        lud16: 'lud16value',
      );

      final uri2 = NostrWalletConnectUri(
        walletPubkey: 'pubkey123',
        relays: ['wss://relay1.example.com', 'wss://relay2.example.com'],
        secret: 'secret123',
        lud16: 'lud16value',
      );

      expect(uri1, equals(uri2));
    });

    test('should correctly compare two different instances', () {
      final uri1 = NostrWalletConnectUri(
        walletPubkey: 'pubkey123',
        relays: ['wss://relay.example.com'],
        secret: 'secret123',
        lud16: 'lud16value',
      );

      final uri2 = NostrWalletConnectUri(
        walletPubkey: 'pubkey456',
        relays: ['wss://relay.example.com'],
        secret: 'secret123',
        lud16: 'lud16value',
      );

      expect(uri1, isNot(equals(uri2)));
    });

    test('should handle legacy constructor', () {
      final uri = NostrWalletConnectUri.legacy(
        walletPubkey: 'pubkey123',
        relay: 'wss://relay.example.com',
        secret: 'secret123',
        lud16: 'lud16value',
      );

      expect(uri.walletPubkey, equals('pubkey123'));
      expect(uri.relays, equals(['wss://relay.example.com']));
      expect(uri.relay, equals('wss://relay.example.com'));
      expect(uri.secret, equals('secret123'));
      expect(uri.lud16, equals('lud16value'));
    });

    test('should create URI string with single relay', () {
      final uri = NostrWalletConnectUri(
        walletPubkey: 'pubkey123',
        relays: ['wss://relay.example.com'],
        secret: 'secret123',
        lud16: 'lud16value',
      );

      final uriString = uri.toUri();
      expect(uriString, contains('nostr+walletconnect://pubkey123'));
      expect(uriString, contains('relays=wss%3A%2F%2Frelay.example.com'));
      expect(uriString, contains('secret=secret123'));
      expect(uriString, contains('lud16=lud16value'));
    });

    test('should create URI string with multiple relays', () {
      final uri = NostrWalletConnectUri(
        walletPubkey: 'pubkey123',
        relays: ['wss://relay1.example.com', 'wss://relay2.example.com'],
        secret: 'secret123',
      );

      final uriString = uri.toUri();
      expect(uriString, contains('nostr+walletconnect://pubkey123'));
      expect(
          uriString,
          contains(
              'relays=wss%3A%2F%2Frelay1.example.com%2Cwss%3A%2F%2Frelay2.example.com'));
      expect(uriString, contains('secret=secret123'));
    });

    test('should create URI with createMultiRelay factory', () {
      final uri = NostrWalletConnectUri.createMultiRelay(
        walletPubkey: 'pubkey123',
        relays: ['wss://relay1.example.com', 'wss://relay2.example.com'],
        secret: 'secret123',
        lud16: 'lud16value',
      );

      expect(uri.walletPubkey, equals('pubkey123'));
      expect(uri.relays,
          equals(['wss://relay1.example.com', 'wss://relay2.example.com']));
      expect(uri.secret, equals('secret123'));
      expect(uri.lud16, equals('lud16value'));
    });

    test('should throw error when createMultiRelay called with empty relays',
        () {
      expect(
        () => NostrWalletConnectUri.createMultiRelay(
          walletPubkey: 'pubkey123',
          relays: [],
          secret: 'secret123',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should round-trip URI creation and parsing', () {
      final originalUri = NostrWalletConnectUri(
        walletPubkey: 'pubkey123',
        relays: ['wss://relay1.example.com', 'wss://relay2.example.com'],
        secret: 'secret123',
        lud16: 'lud16value',
      );

      final uriString = originalUri.toUri();
      final parsedUri = NostrWalletConnectUri.parseConnectionUri(uriString);

      expect(parsedUri, equals(originalUri));
    });

    test(
        'should parse a connection URI with comma-separated relays in the relay parameter',
        () {
      final uri =
          'nostr+walletconnect://pubkey123?relay=wss://relay1.com,wss://relay2.com&secret=secret123';
      final nostrUri = NostrWalletConnectUri.parseConnectionUri(uri);

      expect(nostrUri.walletPubkey, equals('pubkey123'));
      expect(nostrUri.relays, equals(['wss://relay1.com', 'wss://relay2.com']));
      expect(nostrUri.secret, equals('secret123'));
    });
  });
}
