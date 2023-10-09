// ignore_for_file: file_names

import '../event.dart';
import '../pubkey_mapping.dart';

class Nip65 {
  static const int kind = 10002;

  Map<String, ReadWriteMarker?> relays = {};

  Nip65.fromEvent(NostrEvent event) {
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
}
