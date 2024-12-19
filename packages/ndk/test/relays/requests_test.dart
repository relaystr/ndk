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
        kind: Nip01Event.TEXT_NODE_KIND,
        pubKey: key2.publicKey,
        content: "some note from key ${keyNames[key2]}",
        tags: [],
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000);
  }

  Map<KeyPair, Nip01Event> key1TextNotes = {key1: textNote(key1)};
  Map<KeyPair, Nip01Event> key2TextNotes = {key2: textNote(key2)};
  Map<KeyPair, Nip01Event> key3TextNotes = {key3: textNote(key3)};
  Map<KeyPair, Nip01Event> key4TextNotes = {key4: textNote(key4)};

  group('Requests', () {
    test('Request text note', () async {
      MockRelay relay1 = MockRelay(name: "relay 1", explicitPort: 6060);
      await relay1.startServer(textNotes: key1TextNotes);

      final ndk = Ndk(NdkConfig(
        eventVerifier: MockEventVerifier(),
        eventSigner: Bip340EventSigner(
          privateKey: key1.privateKey,
          publicKey: key1.publicKey,
        ),
        cache: MemCacheManager(),
        engine: NdkEngine.RELAY_SETS,
        bootstrapRelays: [relay1.url],
      ));

      final filter =
          Filter(kinds: [Nip01Event.TEXT_NODE_KIND], authors: [key1.publicKey]);

      final query = ndk.requests.query(filters: [filter]);

      await expectLater(query.stream, emitsInAnyOrder(key1TextNotes.values));

      await relay1.stopServer();
    });
  });

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
