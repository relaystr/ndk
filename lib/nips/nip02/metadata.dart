import 'dart:convert';

import 'package:dart_ndk/nips/nip01/helpers.dart';
import 'package:dart_ndk/nips/nip65/read_write_marker.dart';

import '../nip01/event.dart';

class Nip02ContactList {
  static const int kind = 3;

  List<String> contacts = [];
  List<String> contactRelays = [];
  List<String> petnames = [];
  Map<String, ReadWriteMarker> relaysInContent = {};

  int createdAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  List<String> sources = [];

  Nip02ContactList.fromEvent(Nip01Event event) {
    createdAt = event.createdAt;
    for (var tag in event.tags) {
      if (tag is! List<dynamic>) continue;
      final length = tag.length;
      if (length <= 1) continue;
      final name = tag[0];
      final contact = tag[1];
      if (name != "p") continue;
      String relay = '';
      String petname = '';
      if (length>2) {
        relay = tag[2];
        if (length>3) {
          petname = tag[3];
        }
      }
      contacts.add(contact);
      contactRelays.add(relay);
      petnames.add(petname);
    }
    if (Helpers.isNotBlank(event.content)) {
      try {
        Map<String, dynamic> json = jsonDecode(event.content);
        if (json.entries.isNotEmpty) {
          for (var entry in json.entries) {
            try {
              bool read = entry.value["read"]?? false;
              bool write = entry.value["write"]?? false;
              if (read || write) {
                relaysInContent[entry.key] =
                    ReadWriteMarker.from(read: read, write: write);
              }
            } catch (e) {
              print("Could not parse relay ${entry.key} , content : ${event.content}");
            }
          }
        }
      } catch (e) {
        // invalid json in content, ignore
      }

    }
    if (event.sources!=null) {
      sources.addAll(event.sources);
    }
  }

  Nip01Event toEvent(String pubKey) {
    return Nip01Event(
      pubKey: pubKey,
      kind: Nip02ContactList.kind,
      tags: contacts.map((contact) {
        int idx = contacts.indexOf(contact);
        List<String> list = ["p", contact, contactRelays[idx], petnames[idx]];
        return list;
      }).toList(),
      content: "",
      publishAt: createdAt,
    );
  }
}
