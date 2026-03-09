import 'package:ndk/shared/helpers/relay_helper.dart';
import 'package:test/test.dart';

void main() {
  group('cleanRelayUrl RFC 3986 normalization', () {
    test('lowercases scheme (RFC 3986)', () {
      expect(cleanRelayUrl('WSS://relay.damus.io'), 'wss://relay.damus.io');
      expect(cleanRelayUrl('WsS://relay.damus.io'), 'wss://relay.damus.io');
      expect(cleanRelayUrl('WS://localhost'), 'ws://localhost');
    });

    test('lowercases host (RFC 3986)', () {
      expect(cleanRelayUrl('wss://RELAY.DAMUS.IO'), 'wss://relay.damus.io');
      expect(cleanRelayUrl('wss://Relay.Damus.IO'), 'wss://relay.damus.io');
      expect(cleanRelayUrl('wss://LOCALHOST'), 'wss://localhost');
    });

    test('lowercases both scheme and host (RFC 3986)', () {
      expect(cleanRelayUrl('WSS://RELAY.DAMUS.IO'), 'wss://relay.damus.io');
    });

    test('removes default port 443 for wss (RFC 3986)', () {
      expect(cleanRelayUrl('wss://relay.damus.io:443'), 'wss://relay.damus.io');
    });

    test('removes default port 80 for ws (RFC 3986)', () {
      expect(cleanRelayUrl('ws://localhost:80'), 'ws://localhost');
    });

    test('preserves non-default ports', () {
      expect(cleanRelayUrl('wss://relay.damus.io:8080'),
          'wss://relay.damus.io:8080');
      expect(cleanRelayUrl('ws://localhost:8080'), 'ws://localhost:8080');
      expect(
          cleanRelayUrl('wss://relay.damus.io:80'), 'wss://relay.damus.io:80');
      expect(cleanRelayUrl('ws://localhost:443'), 'ws://localhost:443');
    });

    test('preserves query string', () {
      expect(cleanRelayUrl('wss://relay.damus.io/path?query=value'),
          'wss://relay.damus.io/path?query=value');
    });

    test('preserves fragment', () {
      expect(cleanRelayUrl('wss://relay.damus.io/path#section'),
          'wss://relay.damus.io/path#section');
    });

    test('preserves query and fragment together', () {
      expect(cleanRelayUrl('wss://relay.damus.io/path?query=value#section'),
          'wss://relay.damus.io/path?query=value#section');
    });

    test('normalizes host while preserving query and fragment', () {
      expect(cleanRelayUrl('wss://RELAY.DAMUS.IO/path?query=value#section'),
          'wss://relay.damus.io/path?query=value#section');
    });

    test('normalizes percent-encoding in query string (RFC 3986)', () {
      // %41 = 'A' (unreserved) should be decoded
      expect(cleanRelayUrl('wss://relay.damus.io/path?key%41=value'),
          'wss://relay.damus.io/path?keyA=value');
      // %2f = '/' (reserved) should stay encoded but uppercase
      expect(cleanRelayUrl('wss://relay.damus.io/path?key=%2fvalue'),
          'wss://relay.damus.io/path?key=%2Fvalue');
    });

    test('normalizes percent-encoding in fragment (RFC 3986)', () {
      // %7E = '~' (unreserved) should be decoded
      expect(cleanRelayUrl('wss://relay.damus.io/path#section%7E'),
          'wss://relay.damus.io/path#section~');
      // %23 = '#' (reserved) should stay encoded but uppercase
      expect(cleanRelayUrl('wss://relay.damus.io/path#section%2f'),
          'wss://relay.damus.io/path#section%2F');
    });

    test('removes dot segments from path (RFC 3986 Section 5.2.4)', () {
      expect(cleanRelayUrl('wss://relay.damus.io/a/./b'),
          'wss://relay.damus.io/a/b');
      expect(cleanRelayUrl('wss://relay.damus.io/a/../b'),
          'wss://relay.damus.io/b');
      expect(cleanRelayUrl('wss://relay.damus.io/a/b/c/../d'),
          'wss://relay.damus.io/a/b/d');
      expect(cleanRelayUrl('wss://relay.damus.io/a/b/../../../c'),
          'wss://relay.damus.io/c');
    });

    test(
        'decodes percent-encoded unreserved characters (RFC 3986 Section 6.2.2.2)',
        () {
      // %41 = 'A', %7E = '~', %2D = '-'
      expect(cleanRelayUrl('wss://relay.damus.io/path%41'),
          'wss://relay.damus.io/pathA');
      expect(cleanRelayUrl('wss://relay.damus.io/path%7E'),
          'wss://relay.damus.io/path~');
      expect(cleanRelayUrl('wss://relay.damus.io/path%2D'),
          'wss://relay.damus.io/path-');
    });

    test('uppercases hex digits in percent-encoding (RFC 3986 Section 6.2.2.2)',
        () {
      // %2f (slash) should become %2F
      expect(cleanRelayUrl('wss://relay.damus.io/path%2fto'),
          'wss://relay.damus.io/path%2Fto');
      expect(cleanRelayUrl('wss://relay.damus.io/path%2a'),
          'wss://relay.damus.io/path%2A');
    });

    test('keeps reserved characters percent-encoded (RFC 3986)', () {
      // Reserved characters should stay encoded: / ? # [ ] @ ! $ & ' ( ) * + , ; =
      expect(cleanRelayUrl('wss://relay.damus.io/path%2F'),
          'wss://relay.damus.io/path%2F');
      expect(cleanRelayUrl('wss://relay.damus.io/path%3F'),
          'wss://relay.damus.io/path%3F');
    });
  });
}
