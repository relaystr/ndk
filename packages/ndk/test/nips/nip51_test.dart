import 'package:ndk/domain_layer/entities/nip_01_utils.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/data_layer/repositories/signers/bip340_event_signer.dart';
import 'package:ndk/domain_layer/entities/nip_01_event.dart';
import 'package:ndk/shared/nips/nip01/helpers.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:ndk/domain_layer/entities/nip_51_list.dart';
import 'package:test/test.dart';

void main() {
  group('Nip51 Relay Sets', () {
    test('fromEvent public', () async {
      final event = Nip01Event(
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        pubKey: 'pubkeyUser1',
        kind: Nip51List.kRelaySet,
        content: "",
        tags: [
          ['d', 'test'],
          ['relay', 'wss://example.com'],
          ['relay', 'wss://example.org'],
          ['invalid'],
        ],
      );
      final nip51RelaySet = await Nip51Set.fromEvent(event, null);
      expect(['wss://example.com', 'wss://example.org'],
          nip51RelaySet!.publicRelays);

      Nip01Event toEvent = await nip51RelaySet.toEvent(null);
      event.tags.removeLast();
      expect(event.pubKey, toEvent.pubKey);
      expect(event.content, toEvent.content);
      expect(event.kind, toEvent.kind);
      expect(event.createdAt, toEvent.createdAt);
      expect(event.tags, toEvent.tags);
    });
    test('fromEvent private', () async {
      KeyPair key1 = Bip340.generatePrivateKey();
      Bip340EventSigner signer = Bip340EventSigner(
        privateKey: key1.privateKey,
        publicKey: key1.publicKey,
      );

      Nip51Set relaySet = Nip51Set(
          pubKey: key1.publicKey,
          kind: Nip51List.kRelaySet,
          name: "test",
          createdAt: Helpers.now,
          elements: []);
      relaySet.privateRelays = ['wss://example.com', 'wss://example.org'];
      Nip01Event event = await relaySet.toEvent(signer);
      Nip51Set? from = await Nip51Set.fromEvent(event, signer);

      expect(relaySet.privateRelays, from!.privateRelays);
    });
  });
  group('Nip51 Relay Lists', () {
    test('fromEvent public', () async {
      final event = Nip01Event(
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        pubKey: 'pubkeyUser1',
        kind: Nip51List.kSearchRelays,
        content: "",
        tags: [
          ['relay', 'wss://example.com'],
          ['relay', 'wss://example.org'],
          ['invalid'],
        ],
      );
      final nip51RelayList = await Nip51List.fromEvent(event, null);
      expect(['wss://example.com', 'wss://example.org'],
          nip51RelayList.publicRelays);

      Nip01Event toEvent = await nip51RelayList.toEvent(null);
      event.tags.removeLast();
      expect(event.pubKey, toEvent.pubKey);
      expect(event.content, toEvent.content);
      expect(event.kind, toEvent.kind);
      expect(event.createdAt, toEvent.createdAt);
      expect(event.tags, toEvent.tags);
    });
    test('fromEvent private', () async {
      KeyPair key1 = Bip340.generatePrivateKey();
      Bip340EventSigner signer = Bip340EventSigner(
        privateKey: key1.privateKey,
        publicKey: key1.publicKey,
      );

      Nip51List relayList = Nip51List(
          pubKey: key1.publicKey,
          kind: Nip51List.kSearchRelays,
          createdAt: Helpers.now,
          elements: []);
      relayList.privateRelays = ['wss://example.com', 'wss://example.org'];
      Nip01Event event = await relayList.toEvent(signer);
      Nip51List? from = await Nip51List.fromEvent(event, signer);

      expect(relayList.privateRelays, from.privateRelays);
    });

    test('toEvent, fromEvent set metadata', () async {
      KeyPair key1 = Bip340.generatePrivateKey();
      Bip340EventSigner signer = Bip340EventSigner(
        privateKey: key1.privateKey,
        publicKey: key1.publicKey,
      );
      final nip51Set = Nip51Set(
        name: "metdataSet",
        title: "My Set Title",
        description: "This is a description",
        image: "https://example.com/image.png",
        pubKey: 'pubkeyUser1',
        kind: Nip51List.kRelaySet,
        createdAt: Helpers.now,
        elements: [],
      );
      expect(nip51Set.title, "My Set Title");
      expect(nip51Set.description, "This is a description");
      expect(nip51Set.image, "https://example.com/image.png");

      Nip01Event event = await nip51Set.toEvent(signer);
      Nip51Set? from = await Nip51Set.fromEvent(event, signer);
      expect(from!.name, "metdataSet");
      expect(from.title, "My Set Title");
      expect(from.description, "This is a description");
      expect(from.image, "https://example.com/image.png");
    });
  });
}
