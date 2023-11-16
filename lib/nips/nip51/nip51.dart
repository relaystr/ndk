import 'package:dart_ndk/nips/nip65/read_write_marker.dart';

import '../nip01/event.dart';

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

  Nip51RelaySet.fromEvent(Nip01Event event) {
    pubKey = event.pubKey;
    id = event.id;
    createdAt = event.createdAt!;
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

  Nip01Event toEvent() {
    Nip01Event event = Nip01Event(
      pubKey: pubKey,
      kind: CATEGORIZED_RELAY_SETS,
      tags: [["d", name]]..addAll(relays.map((entry) => ["r",entry])),
      content: "",
      createdAt: createdAt,
    );
    return event;
  }
}