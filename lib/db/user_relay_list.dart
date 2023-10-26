import 'package:dart_ndk/nips/nip01/event.dart';
import 'package:dart_ndk/nips/nip02/contact_list.dart';
import 'package:dart_ndk/nips/nip65/read_write_marker.dart';
import 'package:isar/isar.dart';

import '../nips/nip65/nip65.dart';

part 'user_relay_list.g.dart';

@collection
class UserRelayList {
  String id;
  int createdAt;
  int refreshedTimestamp;

  List<RelayListItem> items;

  UserRelayList(this.id, this.items, this.createdAt, this.refreshedTimestamp);

  @ignore
  List<String> get urls => items.map((e) => e.url).toList();

  static UserRelayList fromNip65(Nip65 nip65) {
    return UserRelayList(
        nip65.pubKey,
        nip65.relays.entries.map((entry) => RelayListItem(entry.key, entry.value)).toList(),
        nip65.createdAt,
        DateTime.now().millisecondsSinceEpoch ~/1000);
  }

  static UserRelayList fromNip02EventContent(Nip01Event event) {
    return UserRelayList(
        event.pubKey,
        ContactList.relaysFromContent(event).entries.map((entry) => RelayListItem(entry.key, entry.value)).toList(),
        event.createdAt!,
        DateTime.now().millisecondsSinceEpoch ~/1000);
  }
}

@embedded
class RelayListItem {
  String url;
  ReadWriteMarker marker;

  RelayListItem(this.url, this.marker);
}
