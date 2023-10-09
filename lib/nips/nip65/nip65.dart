// ignore_for_file: file_names

import 'package:dart_ndk/nips/nip65/read_write_marker.dart';

import '../nip01/event.dart';

class Nip65 {
  static const int kind = 10002;

  Map<String, ReadWriteMarker> relays = {};

  int createdAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  Nip65(this.relays);

  Nip65.fromEvent(Nip01Event event) {
    createdAt = event.createdAt;
    for (var tag in event.tags) {
      if (tag is! List<dynamic>) continue;
      final length = tag.length;
      if (length <= 1) continue;
      final name = tag[0];
      final url = tag[1];
      if (name != "r") continue;
      ReadWriteMarker? marker = ReadWriteMarker.readWrite;
      if (length > 2) {
        var operType = tag[2];
        switch (operType) {
          case "read":
            marker = ReadWriteMarker.readOnly;
            break;
          case "write":
            marker = ReadWriteMarker.writeOnly;
            break;
        }
      }
      relays[url] = marker;
    }
  }

  Nip01Event toEvent(String pubKey) {
    return Nip01Event(
      pubKey: pubKey,
      kind: Nip65.kind,
      tags: relays.entries.map((entry) {
        final url = entry.key;
        final marker = entry.value;
        List<String> list = ["r", url];
        if (marker == ReadWriteMarker.readOnly) {
          list.add("read");
        }
        if (marker == ReadWriteMarker.writeOnly) {
          list.add("write");
        }
        return list;
      }).toList(),
      content: "",
      publishAt: createdAt,
    );
  }
}
