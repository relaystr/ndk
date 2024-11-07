// ignore_for_file: avoid_print
import 'dart:developer';

import 'package:ndk/config/bootstrap_relays.dart';
import 'package:ndk/domain_layer/entities/global_state.dart';
import 'package:ndk/domain_layer/entities/request_state.dart';
import 'package:ndk/domain_layer/usecases/inbox_outbox/inbox_outbox.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/presentation_layer/init.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:ndk/domain_layer/entities/read_write_marker.dart';
import 'package:ndk/domain_layer/usecases/relay_jit_manager/relay_jit.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../mocks/mock_event_verifier.dart';

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

  group('check doesRelayCoverPubkey()', () {
    CacheManager cacheManager = MemCacheManager();
    EventVerifier eventVerifier = MockEventVerifier();
    GlobalState globalState = GlobalState();

    // setup
    JitEngine relayJitManager = JitEngine(
      cache: cacheManager,
      ignoreRelays: [],
      seedRelays: DEFAULT_BOOTSTRAP_RELAYS,
      globalState: globalState,
    );

    onMessage(Nip01Event event, RequestState requestState) async {
      log("onMessage(${event.content}, ${requestState.id})");
    }

    RelayJit relayReadOnly =
        RelayJit(url: 'wss://relay.camelus.app', onMessage: onMessage);
    relayReadOnly.assignedPubkeys
        .add(RelayJitAssignedPubkey(key1.publicKey, ReadWriteMarker.readOnly));

    RelayJit relayWriteOnly =
        RelayJit(url: 'wss://relay.camelus.app', onMessage: onMessage);
    relayWriteOnly.assignedPubkeys
        .add(RelayJitAssignedPubkey(key1.publicKey, ReadWriteMarker.writeOnly));

    RelayJit relayReadWrite =
        RelayJit(url: 'wss://relay.camelus.app', onMessage: onMessage);
    relayReadWrite.assignedPubkeys
        .add(RelayJitAssignedPubkey(key1.publicKey, ReadWriteMarker.readWrite));

    RelayJit relayUnassigend =
        RelayJit(url: 'wss://relay.camelus.app', onMessage: onMessage);

    globalState.connectedRelays.add(relayReadOnly);
    globalState.connectedRelays.add(relayWriteOnly);
    globalState.connectedRelays.add(relayReadWrite);
    globalState.connectedRelays.add(relayUnassigend);
    test('test readOnly relay', () {
      // check
      final resultRequestRo = JitEngine.doesRelayCoverPubkey(
          relayReadOnly, key1.publicKey, ReadWriteMarker.readOnly);

      final resultRequestWo = JitEngine.doesRelayCoverPubkey(
          relayReadOnly, key1.publicKey, ReadWriteMarker.writeOnly);

      final resultRequestRW = JitEngine.doesRelayCoverPubkey(
          relayReadOnly, key1.publicKey, ReadWriteMarker.readWrite);

      expect(resultRequestRo, true);
      expect(resultRequestWo, false);
      expect(resultRequestRW, false);
    });

    test('test writeOnly relay', () {
      // check
      final resultRequestRo = JitEngine.doesRelayCoverPubkey(
          relayWriteOnly, key1.publicKey, ReadWriteMarker.readOnly);

      final resultRequestWo = JitEngine.doesRelayCoverPubkey(
          relayWriteOnly, key1.publicKey, ReadWriteMarker.writeOnly);

      final resultRequestRW = JitEngine.doesRelayCoverPubkey(
          relayWriteOnly, key1.publicKey, ReadWriteMarker.readWrite);

      expect(resultRequestRo, false);
      expect(resultRequestWo, true);
      expect(resultRequestRW, false);
    });

    test('test readWrite relay', () {
      // check
      final resultRequestRo = JitEngine.doesRelayCoverPubkey(
          relayReadWrite, key1.publicKey, ReadWriteMarker.readOnly);

      final resultRequestWo = JitEngine.doesRelayCoverPubkey(
          relayReadWrite, key1.publicKey, ReadWriteMarker.writeOnly);

      final resultRequestRW = JitEngine.doesRelayCoverPubkey(
          relayReadWrite, key1.publicKey, ReadWriteMarker.readWrite);

      expect(resultRequestRo, true);
      expect(resultRequestWo, true);
      expect(resultRequestRW, true);
    });
    test('relay without assignments', () {
      // check
      final resultRequestRo = JitEngine.doesRelayCoverPubkey(
          relayUnassigend, key1.publicKey, ReadWriteMarker.readOnly);

      final resultRequestWo = JitEngine.doesRelayCoverPubkey(
          relayUnassigend, key1.publicKey, ReadWriteMarker.writeOnly);

      final resultRequestRW = JitEngine.doesRelayCoverPubkey(
          relayUnassigend, key1.publicKey, ReadWriteMarker.readWrite);

      expect(resultRequestRo, false);
      expect(resultRequestWo, false);
      expect(resultRequestRW, false);
    });
  });
}
