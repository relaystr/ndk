import '../nip01/event.dart';

class Nip02ContactList {
  static const int kind = 3;

  List<String> contacts = [];
  List<String> relays = [];
  List<String> petnames = [];

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
      relays.add(relay);
      petnames.add(petname);
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
        List<String> list = ["p", contact, relays[idx], petnames[idx]];
        return list;
      }).toList(),
      content: "",
      publishAt: createdAt,
    );
  }
}
