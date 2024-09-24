import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ndk/domain_layer/entities/relay_info.dart';

void main() {
  group('RelayInfo', () {

    test('fromJson creates RelayInfo from valid JSON', () {
      final json = {
        "name": "Relay 1",
        "description": "Test relay",
        "pubkey": "abc123",
        "contact": "contact@test.com",
        "supported_nips": [1, 2, 3],
        "software": "relay-software",
        "version": "1.0.0",
        "icon": "https://example.com/icon.png"
      };
      final relayInfo = RelayInfo.fromJson(json, "https://example.com");

      expect(relayInfo.name, equals("Relay 1"));
      expect(relayInfo.description, equals("Test relay"));
      expect(relayInfo.pubKey, equals("abc123"));
      expect(relayInfo.contact, equals("contact@test.com"));
      expect(relayInfo.nips, equals([1, 2, 3]));
      expect(relayInfo.software, equals("relay-software"));
      expect(relayInfo.version, equals("1.0.0"));
      expect(relayInfo.icon, equals("https://example.com/icon.png"));
    });

    test('fromJson uses default icon when icon is null', () {
      final json = {
        "name": "Relay 1",
        "description": "Test relay",
        "pubkey": "abc123",
        "contact": "contact@test.com",
        "supported_nips": [1, 2, 3],
        "software": "relay-software",
        "version": "1.0.0",
      };
      final relayInfo = RelayInfo.fromJson(json, "https://example.com");

      expect(relayInfo.icon, equals("https://example.com/favicon.ico"));
    });
  });
}
