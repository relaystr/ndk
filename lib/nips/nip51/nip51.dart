import 'dart:convert';

import 'package:dart_ndk/nips/nip01/event_signer.dart';
import 'package:dart_ndk/nips/nip01/helpers.dart';

import '../nip01/event.dart';
import '../nip04/nip04.dart';

class Nip51RelaySet {
  static const int MUTE = 10000;
  static const int PIN = 10001;
  static const int CATEGORIZED_PEOPLE = 30000;
  static const int CATEGORIZED_BOOKMARKS = 30001;
  static const int CATEGORIZED_RELAY_SETS = 30002;

  late String id;
  late String pubKey;
  late String name;

  List<String> relays = [];

  late int createdAt;

  @override
  // coverage:ignore-start
  String toString() {
    return 'Nip51RelaySet { urls: $relays}';
  }

  Nip51RelaySet({required this.pubKey, required this.name, required this.relays, required this.createdAt});

  Nip51RelaySet.fromEvent(Nip01Event event, EventSigner? signer) {
    pubKey = event.pubKey;
    id = event.id;
    createdAt = event.createdAt!;
    if (Helpers.isNotBlank(event.content) && signer!=null && signer.canSign()) {
      try {
        var json = Nip04.decrypt(signer.getPrivateKey()!, signer.getPublicKey(), event.content);
        List<dynamic> tags = jsonDecode(json);
        for (var tag in tags) {
          if (tag is! List<dynamic>) continue;
          final length = tag.length;
          if (length <= 1) continue;
          final tagName = tag[0];
          final value = tag[1];
          if (tagName == "d") {
            name = value;
            continue;
          }
          if (tagName != "r") continue;
          relays.add(value);
        }
      } catch (e) {
        name = "<invalid encrypted content>";
        print(e);
      }
    } else {
      for (var tag in event.tags) {
        if (tag is! List<dynamic>) continue;
        final length = tag.length;
        if (length <= 1) continue;
        final tagName = tag[0];
        final value = tag[1];
        if (tagName == "d") {
          name = value;
          continue;
        }
        if (tagName != "r") continue;
        relays.add(value);
      }
    }
  }

  Nip01Event toPublicEvent() {
    Nip01Event event = Nip01Event(
      pubKey: pubKey,
      kind: CATEGORIZED_RELAY_SETS,
      tags: [["d", name]]..addAll(relays.map((entry) => ["r",entry])),
      content: "",
      createdAt: createdAt,
    );
    return event;
  }

  Nip01Event toPrivateEvent(EventSigner signer) {
    String json = jsonEncode( [["d", name]]..addAll(relays.map((entry) => ["r",entry])));
    var resultStr = Nip04.encrypt(signer.getPrivateKey()!, signer.getPublicKey(), json);
    Nip01Event event = Nip01Event(
      pubKey: pubKey,
      kind: CATEGORIZED_RELAY_SETS,
      tags: [],
      content: resultStr,
      createdAt: createdAt,
    );
    return event;
  }
}
