import 'dart:convert';

import 'package:dart_ndk/nips/nip01/event_signer.dart';
import 'package:dart_ndk/nips/nip01/helpers.dart';

import '../nip01/event.dart';
import '../nip04/nip04.dart';

class Nip51List {
  static const int MUTE = 10000;
  static const int PIN = 10001;
  static const int BOOKMARKS = 10003;
  static const int COMMUNITIES = 10004;
  static const int PUBLIC_CHATS = 10005;
  static const int BLOCKED_RELAYS = 10006;
  static const int SEARCH_RELAYS = 10007;
  static const int INTERESTS = 10015;
  static const int EMOJIS = 10030;


  static const int FOLLOW_SET = 30000;
  static const int RELAY_SET = 30002;
  static const int BOOKMARKS_SET = 30003;
  static const int CURATION_SET = 30004;
  static const int INTERESTS_SET = 30015;
  static const int EMOJIS_SET = 30030;

  late String id;
  late String pubKey;
  late int kind;

  List<String>? relays;

  late int createdAt;

  @override
  // coverage:ignore-start
  String toString() {
    return 'Nip51List { $kind}';
  }

  String get displayTitle {
    if (kind==Nip51List.SEARCH_RELAYS) {
      return "Search";
    }
    if (kind==Nip51List.BLOCKED_RELAYS) {
      return "Blocked";
    }
    return "kind $kind";
  }

  Nip51List({required this.pubKey, required this.kind, required this.createdAt, this.relays});

  Nip51List.fromEvent(Nip01Event event, EventSigner? signer) {
    pubKey = event.pubKey;
    kind = event.kind;
    id = event.id;
    createdAt = event.createdAt;
    if (event.kind == Nip51List.SEARCH_RELAYS || event.kind == Nip51List.BLOCKED_RELAYS) {
      relays = [];
    }
    if (Helpers.isNotBlank(event.content) && signer!=null && signer.canSign()) {
      try {
        var json = Nip04.decrypt(signer.getPrivateKey()!, signer.getPublicKey(), event.content);
        List<dynamic> tags = jsonDecode(json);
        parseTags(tags);
      } catch (e) {
        print(e);
      }
    } else {
      parseTags(event.tags);
    }
  }

  void parseTags(List tags) {
    for (var tag in tags) {
      if (tag is! List<dynamic>) continue;
      final length = tag.length;
      if (length <= 1) continue;
      final tagName = tag[0];
      final value = tag[1];
      if (tagName == "relay") {
        if (relays==null) {
          relays = [];
        }
        relays!.add(value);
      }
    }
  }

  Nip01Event toPublicEvent() {
    Nip01Event event = Nip01Event(
      pubKey: pubKey,
      kind: kind,
      // TODO for other kinds
      tags: relays!.map((entry) => ["relay",entry]).toList(),
      content: "",
      createdAt: createdAt,
    );
    return event;
  }

  Nip01Event toPrivateEvent(EventSigner signer) {
    String json = jsonEncode( relays!.map((entry) => ["r",entry]).toList());
    var resultStr = Nip04.encrypt(signer.getPrivateKey()!, signer.getPublicKey(), json);
    Nip01Event event = Nip01Event(
      pubKey: pubKey,
      kind: kind,
      tags: [],
      content: resultStr,
      createdAt: createdAt,
    );
    return event;
  }

  void addRelay(String relayUrl) {
    relays ??= [];
    relays!.add(relayUrl);
  }
}

class Nip51Set extends Nip51List {
  late String name;
  String? title;
  String? description;
  String? image;

  @override
  // coverage:ignore-start
  String toString() {
    return 'Nip51Set { $name}';
  }

  Nip51Set({required String pubKey, required this.name, required int createdAt, this.title}) : super(pubKey: pubKey, kind: Nip51List.RELAY_SET, createdAt: createdAt);

  static Nip51Set? fromEvent(Nip01Event event, EventSigner? signer) {
    String? name = event.getDtag();
    if (name==null || event.kind!=Nip51List.RELAY_SET) {
      return null;
    }
    Nip51Set set = Nip51Set(pubKey: event.pubKey, name: name!, createdAt: event.createdAt);
    set.id = event.id;
    if (Helpers.isNotBlank(event.content) && signer!=null && signer.canSign()) {
      try {
        var json = Nip04.decrypt(signer.getPrivateKey()!, signer.getPublicKey(), event.content);
        List<dynamic> tags = jsonDecode(json);
        set.parseTags(tags);
        set.parseSetTags(tags);
      } catch (e) {
        set.name = "<invalid encrypted content>";
        print(e);
      }
    } else {
      set.parseTags(event.tags);
      set.parseSetTags(event.tags);
    }
    return set;
  }

  Nip01Event toPublicEvent() {
    Nip01Event event = Nip01Event(
      pubKey: pubKey,
      kind: kind,
      tags: [["d", name]]..addAll(relays!.map((entry) => ["relay",entry])),
      content: "",
      createdAt: createdAt,
    );
    return event;
  }

  Nip01Event toPrivateEvent(EventSigner signer) {
    String json = jsonEncode( [["d", name]]..addAll(relays!.map((entry) => ["relay",entry])));
    var resultStr = Nip04.encrypt(signer.getPrivateKey()!, signer.getPublicKey(), json);
    Nip01Event event = Nip01Event(
      pubKey: pubKey,
      kind: kind,
      tags: [["d", name]],
      content: resultStr,
      createdAt: createdAt,
    );
    return event;
  }

  void parseSetTags(List tags) {
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
      if (tagName == "title") {
        title = value;
        continue;
      }
      if (tagName == "description") {
        description = value;
        continue;
      }
      if (tagName == "image") {
        image = value;
        continue;
      }
    }
  }

}
