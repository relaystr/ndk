// ignore_for_file: file_names

import '../event.dart';
import '../pubkey_mapping.dart';

class Nip65 {
  static const int kind = 10002;

  Map<String, ReadWriteMarker?> relays = {};

  int createdAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  Nip65(this.relays);

  Nip65.fromEvent(NostrEvent event) {
    createdAt = event.createdAt;
    for (var tag in event.tags) {
      if (tag is List<dynamic>) {
        var length = tag.length;
        if (length > 1) {
          var name = tag[0];
          var url = tag[1];
          if (name == "r") {
            ReadWriteMarker? marker;
            if (length > 2) {
              var operType = tag[2];
              if (operType == "read") {
                marker = ReadWriteMarker(read: true);
              } else if (operType == "write") {
                marker = ReadWriteMarker(write: true);
              }
            }
            relays[url] = marker;
          }
        }
      }
    }
  }

  NostrEvent toEvent(String pubKey) {
    return NostrEvent(
        pubKey,
        Nip65.kind,
        relays.entries.map((entry) {
          final url = entry.key;
          final marker = entry.value;
          List<String> list = ["r", url];
          if (marker != null) {
            if (marker.read && !marker.write) {
              list.add("read");
            } else {
              if (marker.write) {
                list.add("write");
              }
            }
          }
          return list;
        }).toList(),
        "",
        publishAt: createdAt);
  }
}
