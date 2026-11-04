import 'package:test/test.dart';
import 'package:ndk/domain_layer/entities/relay_info.dart';

void main() {
  group('RelayInfo', () {
    test('fromJson creates RelayInfo from valid JSON', () {
      final json = {
        "name": "Relay 1",
        "description": "Test relay",
        "banner": "https://example.com/banner.png",
        "icon": "https://example.com/icon.png",
        "pubkey": "abc123",
        "self": "def456",
        "contact": "contact@test.com",
        "supported_nips": [1, 2, 3],
        "software": "relay-software",
        "version": "1.0.0",
        "terms_of_service": "https://example.com/tos",
        "payments_url": "https://example.com/payments",
        "limitation": {
          "max_message_length": 16384,
          "max_subscriptions": 300,
          "max_limit": 5000,
          "max_subid_length": 100,
          "max_event_tags": 100,
          "max_content_length": 8196,
          "min_pow_difficulty": 30,
          "auth_required": true,
          "payment_required": true,
          "restricted_writes": true,
          "created_at_lower_limit": 31536000,
          "created_at_upper_limit": 3,
          "default_limit": 500,
        },
        "fees": {
          "admission": [
            {"amount": 1000000, "unit": "msats"},
          ],
          "subscription": [
            {"amount": 5000000, "unit": "msats", "period": 2592000},
          ],
          "publication": [
            {
              "kinds": [4],
              "amount": 100,
              "unit": "msats",
            },
          ],
        },
      };
      final relayInfo = RelayInfo.fromJson(json);

      expect(relayInfo.name, equals("Relay 1"));
      expect(relayInfo.description, equals("Test relay"));
      expect(relayInfo.banner, equals("https://example.com/banner.png"));
      expect(relayInfo.icon, equals("https://example.com/icon.png"));
      expect(relayInfo.pubKey, equals("abc123"));
      expect(relayInfo.self, equals("def456"));
      expect(relayInfo.contact, equals("contact@test.com"));
      expect(relayInfo.nips, equals(['1', '2', '3']));
      expect(relayInfo.software, equals("relay-software"));
      expect(relayInfo.version, equals("1.0.0"));
      expect(relayInfo.termsOfService, equals("https://example.com/tos"));
      expect(relayInfo.paymentsUrl, equals("https://example.com/payments"));

      final limitation = relayInfo.limitation!;
      expect(limitation.maxMessageLength, 16384);
      expect(limitation.maxSubscriptions, 300);
      expect(limitation.maxLimit, 5000);
      expect(limitation.maxSubidLength, 100);
      expect(limitation.maxEventTags, 100);
      expect(limitation.maxContentLength, 8196);
      expect(limitation.minPowDifficulty, 30);
      expect(limitation.authRequired, isTrue);
      expect(limitation.paymentRequired, isTrue);
      expect(limitation.restrictedWrites, isTrue);
      expect(limitation.createdAtLowerLimit, 31536000);
      expect(limitation.createdAtUpperLimit, 3);
      expect(limitation.defaultLimit, 500);

      final fees = relayInfo.fees!;
      expect(fees.admission.single.amount, 1000000);
      expect(fees.admission.single.unit, "msats");
      expect(fees.subscription.single.period, 2592000);
      expect(fees.publication.single.kinds, [4]);
      expect(fees.publication.single.amount, 100);
    });

    test('fromJson leaves omitted fields null', () {
      final relayInfo = RelayInfo.fromJson({});

      expect(relayInfo.name, isNull);
      expect(relayInfo.icon, isNull);
      expect(relayInfo.limitation, isNull);
      expect(relayInfo.fees, isNull);
      expect(relayInfo.nips, isEmpty);
    });

    test('fromJson reads fields with an unexpected type as null', () {
      final relayInfo = RelayInfo.fromJson({
        "name": 42,
        "supported_nips": "1",
        "limitation": {"max_limit": "5000", "auth_required": "true"},
        "fees": {
          "admission": [
            "free",
            {"amount": "1000", "unit": "msats"},
          ],
          "publication": {"amount": 100},
        },
      });

      expect(relayInfo.name, isNull);
      expect(relayInfo.nips, isEmpty);
      expect(relayInfo.limitation!.maxLimit, isNull);
      expect(relayInfo.limitation!.authRequired, isNull);
      expect(relayInfo.fees!.admission.single.amount, isNull);
      expect(relayInfo.fees!.admission.single.unit, "msats");
      expect(relayInfo.fees!.publication, isEmpty);
    });

    test('supportsNip matches numbered and lettered NIPs', () {
      final relayInfo = RelayInfo.fromJson({
        "supported_nips": [1, "11", "7D", "ee"],
      });

      expect(relayInfo.supportsNip('1'), isTrue);
      expect(relayInfo.supportsNip('01'), isTrue);
      expect(relayInfo.supportsNip('11'), isTrue);
      expect(relayInfo.supportsNip('7d'), isTrue);
      expect(relayInfo.supportsNip('EE'), isTrue);
      expect(relayInfo.supportsNip('C7'), isFalse);
      expect(relayInfo.supportsNip('10'), isFalse);
    });
  });
}
