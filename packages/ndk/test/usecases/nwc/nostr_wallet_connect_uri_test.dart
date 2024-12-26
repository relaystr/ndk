import 'package:ndk/domain_layer/usecases/nwc/nostr_wallet_connect_uri.dart';
import 'package:test/test.dart';

void main() {
  group('NostrWalletConnectUri', () {
    test('should parse a valid connection URI', () {
      final uri = 'nostr://pubkey123?relay=wss://relay.example.com&secret=secret123&lud16=lud16value';
      final nostrUri = NostrWalletConnectUri.parseConnectionUri(uri);

      expect(nostrUri.walletPubkey, equals('pubkey123'));
      expect(nostrUri.relay, equals('wss://relay.example.com'));
      expect(nostrUri.secret, equals('secret123'));
      expect(nostrUri.lud16, equals('lud16value'));
    });

    test('should throw an exception for missing required fields', () {
      final uri = 'nostr://pubkey123?relay=wss://relay.example.com';

      expect(
            () => NostrWalletConnectUri.parseConnectionUri(uri),
        throwsA(isA<Exception>()),
      );
    });

    test('should correctly compare two equal instances', () {
      final uri1 = NostrWalletConnectUri(
        walletPubkey: 'pubkey123',
        relay: 'wss://relay.example.com',
        secret: 'secret123',
        lud16: 'lud16value',
      );

      final uri2 = NostrWalletConnectUri(
        walletPubkey: 'pubkey123',
        relay: 'wss://relay.example.com',
        secret: 'secret123',
        lud16: 'lud16value',
      );

      expect(uri1, equals(uri2));
    });

    test('should correctly compare two different instances', () {
      final uri1 = NostrWalletConnectUri(
        walletPubkey: 'pubkey123',
        relay: 'wss://relay.example.com',
        secret: 'secret123',
        lud16: 'lud16value',
      );

      final uri2 = NostrWalletConnectUri(
        walletPubkey: 'pubkey456',
        relay: 'wss://relay.example.com',
        secret: 'secret123',
        lud16: 'lud16value',
      );

      expect(uri1, isNot(equals(uri2)));
    });
  });
}