import '../../shared/helpers/relay_helper.dart';
import 'nip_01_event.dart';
import 'read_write_marker.dart';

class Nip65 {
  static const int kKind = 10002;

  late String pubKey;

  Map<String, ReadWriteMarker> relays = {};

  Nip65.fromMap(this.pubKey, Map<String, ReadWriteMarker> map) {
    relays = map;
  } // Pub keys -> markers

  int createdAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  // Nip65(this.relays);

  Map<String, ReadWriteMarker> relaysMap() {
    return relays;
  }

  /// creates a new [Nip65] instance
  Nip65({required this.pubKey, required this.relays, required this.createdAt});

  Nip65.fromEvent(Nip01Event event) {
    pubKey = event.pubKey;
    createdAt = event.createdAt;
    for (var tag in event.tags) {
      final length = tag.length;
      if (length <= 1) continue;
      final name = tag[0];

      // clean the url so it can be used as a unique identifier
      var cleanUrl = cleanRelayUrl(tag[1]);
      if (cleanUrl == null) continue;

      final url = cleanUrl;
      if (name != "r") continue;
      ReadWriteMarker marker = ReadWriteMarker.readWrite;
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
      // a relay listed once per direction is read and write, in either order
      final listed = relays[url];
      relays[url] = listed == null
          ? marker
          : ReadWriteMarker.from(
              read: listed.isRead || marker.isRead,
              write: listed.isWrite || marker.isWrite,
            );
    }
  }

  Nip01Event toEvent() {
    return Nip01Event(
      pubKey: pubKey,
      kind: Nip65.kKind,
      tags: relays.entries.map((entry) {
        ReadWriteMarker marker = entry.value;
        List<String> list = ["r", entry.key];
        if (marker == ReadWriteMarker.readOnly) {
          list.add("read");
        }
        if (marker == ReadWriteMarker.writeOnly) {
          list.add("write");
        }
        return list;
      }).toList(),
      content: "",
      createdAt: createdAt,
    );
  }

  // coverage:ignore-start
  @override
  String toString() {
    return 'Nip65{urls: $relays}';
  }

  // coverage:ignore-end
}
