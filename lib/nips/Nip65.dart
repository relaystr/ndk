// ignore_for_file: file_names

import '../nostr_event.dart';
import '../pubkey_mapping.dart';

class Nip65 {
  static const int kind = 10002;

  Map<String, ReadWriteMarker> relays = {};

  int createdAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  Nip65(this.relays);

  Nip65.fromEvent(NostrEvent event) {
    createdAt = event.createdAt;
    for (var tag in event.tags) {
      if (tag is! List<dynamic>) continue;
      final length = tag.length;
      if (length <= 1) continue;
      final name = tag[0];
      final url = tag[1];
      if (name != "r") continue;
      ReadWriteMarker marker = ReadWriteMarker.readWrite;
      if (length > 2) {
        var operType = tag[2];
        switch (operType) {
          case "read":
            marker = ReadWriteMarker.read;
            break;
          case "write":
            marker = ReadWriteMarker.write;
            break;
          default:
            marker = ReadWriteMarker.readWrite;
            break;
        }
      }
      relays[url] = marker;
    }
  }

  NostrEvent toEvent(String pubKey) {
    return NostrEvent(
      pubKey: pubKey,
      kind: Nip65.kind,
      tags: relays.entries.map((entry) {
        final url = entry.key;
        final marker = entry.value;
        List<String> list = ["r", url];

        if (marker == ReadWriteMarker.read) {
          list.add("read");
        }
        if (marker == ReadWriteMarker.write) {
          list.add("write");
        }

        return list;
      }).toList(),
      content: "",
      publishAt: createdAt,
    );
  }
}
