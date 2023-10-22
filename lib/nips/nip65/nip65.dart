import 'package:dart_ndk/nips/nip65/read_write_marker.dart';
import 'package:isar/isar.dart';

import '../nip01/event.dart';

part 'nip65.g.dart';

@collection
class Nip65 {
  static const int kind = 10002;

  String get id => pubKey;

  @ignore
  late String pubKey;

  List<String> urls = [];
  List<ReadWriteMarker> markers = [];

  Nip65(this.urls, this.markers);

  Nip65.fromMap(String pubKey, Map<String, ReadWriteMarker> map) {
    this.pubKey = pubKey;
    for(MapEntry<String,ReadWriteMarker> entry in map.entries) {
      urls.add(entry.key);
      markers.add(entry.value);
    }
  } // Pub keys -> markers
  // Map<String, dynamic> relays = {};

  int createdAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  // Nip65(this.relays);

  Map<String, ReadWriteMarker> relaysMap() {
    Map<String, ReadWriteMarker> map = {};
    for (var i = 0; i < urls.length; i++) {
      map[urls[i]] = markers[i];
    }
    return map;
  }


  Nip65.fromEvent(Nip01Event event) {
    pubKey = event.pubKey;
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
      urls.add(url);
      markers.add(marker);
    }
  }

  Nip01Event toEvent() {
    return Nip01Event(
      pubKey: pubKey,
      kind: Nip65.kind,
      tags: urls.map((url) {
        ReadWriteMarker marker = markers[urls!.indexOf(url)];
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

  @override
  // coverage:ignore-start
  String toString() {
    return 'Nip65{urls: $urls}';
  }
  // coverage:ignore-end
}
