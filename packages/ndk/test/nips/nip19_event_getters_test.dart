import 'package:ndk/domain_layer/entities/nip_01_utils.dart';
import 'package:ndk/entities.dart';
import 'package:test/test.dart';
import 'package:ndk/shared/nips/nip19/nip19.dart';

void main() {
  group('Nip01Event NIP-19 getters', () {
    group('nevent getter', () {
      test('should encode regular event as nevent', () {
        final event = Nip01Event(
          pubKey:
              '76c71aae3a491f1d9eec47cba17e229cda4113a0bbb6e6ae1776d7643e29cafa',
          kind: 1,
          tags: [],
          content: 'Hello Nostr!',
          createdAt: 1234567890,
        );

        final eventMode = Nip01EventModel.fromEntity(event);

        final nevent = eventMode.nevent;

        expect(nevent.startsWith('nevent1'), true);

        // Verify we can decode it back
        final decoded = Nip19.decodeNevent(nevent);
        expect(decoded.eventId, event.id);
        expect(decoded.author, event.pubKey);
        expect(decoded.kind, event.kind);
      });

      test('should use event sources as relay hints', () {
        final eventInit = Nip01Event(
          pubKey:
              '76c71aae3a491f1d9eec47cba17e229cda4113a0bbb6e6ae1776d7643e29cafa',
          kind: 1,
          tags: [],
          content: 'Hello Nostr!',
          createdAt: 1234567890,
        );
        final event = eventInit
            .copyWith(sources: ['wss://nos.lol/', 'wss://relay.damus.io/']);

        final eventModel = Nip01EventModel.fromEntity(event);

        final nevent = eventModel.nevent;

        final decoded = Nip19.decodeNevent(nevent);
        expect(decoded.relays, eventModel.sources);
      });

      test('should not include relays if sources is empty', () {
        final event = Nip01Event(
          pubKey:
              '76c71aae3a491f1d9eec47cba17e229cda4113a0bbb6e6ae1776d7643e29cafa',
          kind: 1,
          tags: [],
          content: 'Hello Nostr!',
          createdAt: 1234567890,
        );
        final eventModel = Nip01EventModel.fromEntity(event);

        final nevent = eventModel.nevent;

        final decoded = Nip19.decodeNevent(nevent);
        expect(decoded.relays, null);
      });
    });

    group('naddr getter', () {
      test('should encode parameterized replaceable event as naddr', () {
        final event = Nip01Event(
          pubKey:
              '460c25e682fda7832b52d1f22d3d22b3176d972f60dcdc3212ed8c92ef85065c',
          kind: 30023,
          tags: [
            ['d', 'my-article'],
          ],
          content: 'Article content',
          createdAt: 1234567890,
        );
        final eventModel = Nip01EventModel.fromEntity(event);

        final naddr = eventModel.naddr;

        expect(naddr, isNotNull);
        expect(naddr!.startsWith('naddr1'), true);

        // Verify we can decode it back
        final decoded = Nip19.decodeNaddr(naddr);
        expect(decoded.identifier, 'my-article');
        expect(decoded.pubkey, eventModel.pubKey);
        expect(decoded.kind, eventModel.kind);
      });

      test('should encode replaceable event (kind 0) as naddr', () {
        final event = Nip01Event(
          pubKey:
              '460c25e682fda7832b52d1f22d3d22b3176d972f60dcdc3212ed8c92ef85065c',
          kind: 0,
          tags: [
            ['d', ''],
          ],
          content: '{"name":"Alice"}',
          createdAt: 1234567890,
        );
        final eventModel = Nip01EventModel.fromEntity(event);

        final naddr = eventModel.naddr;

        expect(naddr, isNotNull);
        final decoded = Nip19.decodeNaddr(naddr!);
        expect(decoded.identifier, '');
        expect(decoded.kind, 0);
      });

      test('should return null for non-addressable event', () {
        final event = Nip01Event(
          pubKey:
              '460c25e682fda7832b52d1f22d3d22b3176d972f60dcdc3212ed8c92ef85065c',
          kind: 1, // Regular text note, not addressable
          tags: [
            ['d', 'test'],
          ],
          content: 'Hello',
          createdAt: 1234567890,
        );
        final eventModel = Nip01EventModel.fromEntity(event);

        final naddr = eventModel.naddr;

        expect(naddr, isNull);
      });

      test('should return null for addressable event without d tag', () {
        final event = Nip01Event(
          pubKey:
              '460c25e682fda7832b52d1f22d3d22b3176d972f60dcdc3212ed8c92ef85065c',
          kind: 30023,
          tags: [], // No d tag
          content: 'Article content',
          createdAt: 1234567890,
        );
        final eventModel = Nip01EventModel.fromEntity(event);

        final naddr = eventModel.naddr;

        expect(naddr, isNull);
      });

      test('should use event sources as relay hints', () {
        final event = Nip01Event(
          pubKey:
              '460c25e682fda7832b52d1f22d3d22b3176d972f60dcdc3212ed8c92ef85065c',
          kind: 31990,
          tags: [
            ['d', '1685802317447'],
          ],
          content: '{}',
          createdAt: 1234567890,
        );
        final eventWithSources =
            event.copyWith(sources: ['wss://relay.example.com']);

        final eventModel = Nip01EventModel.fromEntity(eventWithSources);

        final naddr = eventModel.naddr;

        expect(naddr, isNotNull);
        final decoded = Nip19.decodeNaddr(naddr!);
        expect(decoded.relays, eventModel.sources);
      });
    });

    group('addressable kinds', () {
      const testPubkey =
          '460c25e682fda7832b52d1f22d3d22b3176d972f60dcdc3212ed8c92ef85065c';

      test('should recognize replaceable event kinds', () {
        final kinds = [0, 3, 41];
        for (final kind in kinds) {
          final event = Nip01Event(
            pubKey: testPubkey,
            kind: kind,
            tags: [
              ['d', ''],
            ],
            content: '',
          );

          final eventModel = Nip01EventModel.fromEntity(event);
          expect(eventModel.naddr, isNotNull,
              reason: 'Kind $kind should be addressable');
        }
      });

      test('should recognize parameterized replaceable event kinds', () {
        final kinds = [10000, 15000, 19999, 30000, 35000, 39999];
        for (final kind in kinds) {
          final event = Nip01Event(
            pubKey: testPubkey,
            kind: kind,
            tags: [
              ['d', 'test'],
            ],
            content: '',
          );

          final eventModel = Nip01EventModel.fromEntity(event);
          expect(eventModel.naddr, isNotNull,
              reason: 'Kind $kind should be addressable');
        }
      });

      test('should not recognize non-addressable kinds', () {
        final kinds = [1, 2, 4, 5, 6, 7, 40, 42, 9999, 20000, 29999, 40000];
        for (final kind in kinds) {
          final event = Nip01Event(
            pubKey: testPubkey,
            kind: kind,
            tags: [
              ['d', 'test'],
            ],
            content: '',
          );
          final eventModel = Nip01EventModel.fromEntity(event);
          expect(eventModel.naddr, isNull,
              reason: 'Kind $kind should not be addressable');
        }
      });
    });
  });
}
