// ignore_for_file: avoid_print

import 'dart:async';

import 'package:test/test.dart';
import 'package:ndk/domain_layer/entities/global_state.dart';
import 'package:ndk/domain_layer/entities/request_state.dart';
import 'package:ndk/domain_layer/usecases/cache_read/cache_read.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/presentation_layer/init.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

import '../mocks/mock_event_verifier.dart';
import '../mocks/mock_relay.dart';

void main() async {
  KeyPair key1 = Bip340.generatePrivateKey();
  KeyPair key2 = Bip340.generatePrivateKey();
  KeyPair key3 = Bip340.generatePrivateKey();
  KeyPair key4 = Bip340.generatePrivateKey();

  Map<KeyPair, String> keyNames = {
    key1: "key1",
    key2: "key2",
    key3: "key3",
    key4: "key4",
  };

  Nip01Event textNote(KeyPair key2) {
    return Nip01Event(
        kind: Nip01Event.kTextNodeKind,
        pubKey: key2.publicKey,
        content: "some note from key ${keyNames[key2]}",
        tags: [],
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000);
  }

  Map<KeyPair, Nip01Event> textNotes = {
    key1: textNote(key1),
    key2: textNote(key2)
  };

  group('Requests', () {
    test('Request text note', () async {
      MockRelay relay1 = MockRelay(name: "relay 1", explicitPort: 6060);
      await relay1.startServer(textNotes: textNotes);

      final ndk = Ndk(NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: MemCacheManager(),
        engine: NdkEngine.RELAY_SETS,
        bootstrapRelays: [relay1.url],
      ));
      ndk.accounts
          .loginPrivateKey(pubkey: key1.publicKey, privkey: key1.privateKey!);

      final filter =
          Filter(kinds: [Nip01Event.kTextNodeKind], authors: [key1.publicKey]);

      final query = ndk.requests.query(filters: [filter]);

      await expectLater(
          query.stream, emitsInAnyOrder([textNotes.values.first]));

      await ndk.destroy();
      expect(ndk.relays.globalState.inFlightRequests.isEmpty, true);
      await relay1.stopServer();
    });

    test('Request multiple filters text note', () async {
      MockRelay relay1 = MockRelay(name: "relay 1", explicitPort: 6060);
      await relay1.startServer(textNotes: textNotes);

      final ndk = Ndk(NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: MemCacheManager(),
        engine: NdkEngine.RELAY_SETS,
        bootstrapRelays: [relay1.url],
      ));
      ndk.accounts
          .loginPrivateKey(pubkey: key1.publicKey, privkey: key1.privateKey!);

      final query = ndk.requests.query(
          // explicitRelays: [relay1.url],
          filters: [
        Filter(kinds: [Nip01Event.kTextNodeKind], authors: [key1.publicKey]),
        Filter(kinds: [Nip01Event.kTextNodeKind], authors: [key2.publicKey])
      ]);

      await expectLater(query.stream, emitsInAnyOrder(textNotes.values));

      // await for (final event in query.stream) {
      //   print(event);
      // }

      await ndk.destroy();
      expect(ndk.relays.globalState.inFlightRequests.isEmpty, true);
      await relay1.stopServer();
    });
    test('Request multiple filters text note JIT', skip: true, () async {
      MockRelay relay1 = MockRelay(name: "relay 1", explicitPort: 6060);
      await relay1.startServer(textNotes: textNotes);

      final ndk = Ndk(NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: MemCacheManager(),
        engine: NdkEngine.JIT,
        bootstrapRelays: [relay1.url],
      ));
      ndk.accounts
          .loginPrivateKey(pubkey: key1.publicKey, privkey: key1.privateKey!);

      final query = ndk.requests.query(
        // explicitRelays: [relay1.url],
          filters: [
            Filter(kinds: [Nip01Event.kTextNodeKind], authors: [key1.publicKey]),
            Filter(kinds: [Nip01Event.kTextNodeKind], authors: [key2.publicKey])
          ]);

      await expectLater(query.stream, emitsInAnyOrder(textNotes.values));

      // await for (final event in query.stream) {
      //   print(event);
      // }

      await ndk.destroy();
      expect(ndk.relays.globalState.inFlightRequests.isEmpty, true);
      await relay1.stopServer();
    });
  });

  // TODO test multiple filters (OR condition)

  // [
  //   {ids: ["ad6137b9a3dc4b393a41d745c483837cfd2379e22ec9916c487d6bd6cfe4b3b7"], kinds: [9041]},
  //   {kinds: [1311, 9735], limit: 200, "#a": ["30311:cf45a6ba1363ad7ed213a078e710d24115ae721c9b47bd1ebf4458eaefb4c2a5:ec9731a5-b1a0-4296-baf4-0f8355687581"]},
  //   {authors: ["63fe6318dc58583cfe16810f86dd09e18bfd76aabc24a0081ce2856f330504ed", "46f5797187ff5cf4dddb33828fb4e1296a7fd0ce666a3f24cdd454329e201480"], kinds: [10000]}
  // ]

  group('immutable filters', () {
    test('Filters are cloned and immutable in query method', () {
      final cache = MemCacheManager();
      final eventVerifier = MockEventVerifier();
      final globalState = GlobalState();
      final init = Initialization(
        globalState: globalState,
        ndkConfig: NdkConfig(
          eventVerifier: eventVerifier,
          cache: cache,
        ),
      );

      // Create a Requests instance
      final requests = Requests(
        defaultQueryTimeout: Duration(seconds: 10),
        globalState: globalState,
        cacheRead: MockCacheRead(cache),
        cacheWrite: init.cacheWrite,
        networkEngine: init.engine,
        relayManager: init.relayManager,
        eventVerifier: eventVerifier,
        eventOutFilters: [],
      );

      // Create an initial filter
      final originalFilter = Filter(
        kinds: [1],
        authors: ['author1'],
      );
      final originalFilterSub = Filter(
        kinds: [1],
        authors: ['author1Sub'],
      );

      //   query
      requests.query(filters: [originalFilter]);

      expect(originalFilter.authors!.length, equals(1));

      //   subscription
      requests.subscription(filters: [originalFilterSub], cacheRead: true);
      expect(originalFilterSub.authors!.length, equals(1));
    });
  });
}

class MockCacheRead extends CacheRead {
  MockCacheRead(super.cacheManager);

  @override
  Future<void> resolveUnresolvedFilters({
    required RequestState requestState,
    required StreamController<Nip01Event> outController,
  }) async {
    for (var filter in requestState.unresolvedFilters) {
      filter.authors = [];
    }
  }
}
