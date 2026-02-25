import 'package:ndk/shared/helpers/relay_helper.dart';
import 'package:test/test.dart';

void main() {
  group('cleanRelayUrl', () {
    group('valid URLs', () {
      test('accepts valid wss URL with port + path', () {
        expect(cleanRelayUrl('wss://relay.damus.io:5000/abc/aa.co.mm'),
            'wss://relay.damus.io:5000/abc/aa.co.mm');
      });

      test('accepts valid wss URL', () {
        expect(cleanRelayUrl('wss://relay.damus.io'), 'wss://relay.damus.io');
      });

      test('accepts valid ws URL', () {
        expect(cleanRelayUrl('ws://localhost'), 'ws://localhost');
      });

      test('accepts URL with port', () {
        expect(cleanRelayUrl('wss://relay.example.com:8080'),
            'wss://relay.example.com:8080');
      });

      test('accepts URL with subdomain', () {
        expect(cleanRelayUrl('wss://nostr.relay.example.com'),
            'wss://nostr.relay.example.com');
      });

      test('accepts IP address', () {
        expect(cleanRelayUrl('wss://192.168.1.1'), 'wss://192.168.1.1');
      });

      test('accepts IP address with port', () {
        expect(
            cleanRelayUrl('wss://192.168.1.1:8080'), 'wss://192.168.1.1:8080');
      });

      test('accepts localhost', () {
        expect(cleanRelayUrl('ws://localhost'), 'ws://localhost');
      });

      test('accepts localhost with port', () {
        expect(cleanRelayUrl('ws://localhost:7777'), 'ws://localhost:7777');
      });
    });

    group('URL cleaning', () {
      test('removes trailing slash', () {
        expect(cleanRelayUrl('wss://relay.damus.io/'), 'wss://relay.damus.io');
      });

      test('trims whitespace', () {
        expect(
            cleanRelayUrl('  wss://relay.damus.io  '), 'wss://relay.damus.io');
      });

      test('decodes percent-encoded URL', () {
        expect(cleanRelayUrl('wss://relay.example%2Ecom'),
            'wss://relay.example.com');
      });

      test('fixes triple slash URL', () {
        expect(cleanRelayUrl('wss:///relay.damus.io'), 'wss://relay.damus.io');
      });

      test('fixes multiple extra slashes', () {
        expect(cleanRelayUrl('wss:////relay.damus.io'), 'wss://relay.damus.io');
      });
    });

    group('invalid URLs', () {
      test('returns null for empty string', () {
        expect(cleanRelayUrl(''), null);
      });

      test('returns null for URL without protocol', () {
        expect(cleanRelayUrl('relay.damus.io'), null);
      });

      test('returns null for http URL', () {
        expect(cleanRelayUrl('http://relay.damus.io'), null);
      });

      test('returns null for https URL', () {
        expect(cleanRelayUrl('https://relay.damus.io'), null);
      });

      test('returns null for URL with only protocol', () {
        expect(cleanRelayUrl('wss://'), null);
      });

      test('returns null for triple slash with no host', () {
        expect(cleanRelayUrl('wss:///'), null);
      });

      test('returns null for invalid characters in host', () {
        expect(cleanRelayUrl('wss://relay space.com'), null);
      });

      test('returns null for host starting with hyphen', () {
        expect(cleanRelayUrl('wss://-relay.com'), null);
      });

      test('returns null for host ending with hyphen', () {
        expect(cleanRelayUrl('wss://relay-.com'), null);
      });
    });
  });

  group('cleanRelayUrls', () {
    test('returns empty list for empty input', () {
      expect(cleanRelayUrls([]), []);
    });

    test('filters out invalid URLs', () {
      final urls = [
        'wss://relay.damus.io',
        'invalid-url',
        'wss://nos.lol',
      ];
      expect(cleanRelayUrls(urls), ['wss://relay.damus.io', 'wss://nos.lol']);
    });

    test('cleans valid URLs', () {
      final urls = [
        'wss://relay.damus.io/',
        '  wss://nos.lol  ',
      ];
      expect(cleanRelayUrls(urls), ['wss://relay.damus.io', 'wss://nos.lol']);
    });

    test('returns empty list when all URLs are invalid', () {
      final urls = [
        'invalid',
        'http://example.com',
        '',
      ];
      expect(cleanRelayUrls(urls), []);
    });

    test('fixes triple slash URLs in list', () {
      final urls = [
        'wss:///relay.damus.io',
        'wss://nos.lol',
      ];
      expect(cleanRelayUrls(urls), ['wss://relay.damus.io', 'wss://nos.lol']);
    });

    test('normalizes URLs with RFC 3986 compliance', () {
      final urls = [
        'WSS://RELAY.DAMUS.IO',
        'wss://nos.lol:443',
        'WS://LOCALHOST:80',
      ];
      expect(cleanRelayUrls(urls),
          ['wss://relay.damus.io', 'wss://nos.lol', 'ws://localhost']);
    });
  });

  group('RELAY_URL_REGEX', () {
    test('matches valid relay URL pattern', () {
      expect(relayUrlRegex.hasMatch('wss://relay.damus.io'), true);
      expect(relayUrlRegex.hasMatch('ws://localhost'), true);
      expect(relayUrlRegex.hasMatch('wss://192.168.1.1'), true);
      expect(relayUrlRegex.hasMatch('wss://relay.example.com:8080'), true);
    });

    test('does not match invalid patterns', () {
      expect(relayUrlRegex.hasMatch('http://example.com'), false);
      expect(relayUrlRegex.hasMatch('wss://'), false);
      expect(relayUrlRegex.hasMatch('wss:///example.com'), false);
    });
  });
}
