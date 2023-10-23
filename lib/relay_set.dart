import 'package:dart_ndk/pubkey_mapping.dart';
import 'package:dart_ndk/read_write.dart';
import 'package:isar/isar.dart';

import 'nips/nip65/read_write_marker.dart';

part 'relay_set.g.dart';

@embedded
class RelaySetItem {
  String url;
  List<PubkeyMapping> pubKeyMappings;

  RelaySetItem(this.url, this.pubKeyMappings);
}

@collection
class RelaySet {
  String get id => name + pubKey;

  List<String> get urls => items.map((e) => e.url).toList();

  late String name;

  late String pubKey;

  int relayMinCountPerPubkey;

  RelayDirection direction;

  List<RelaySetItem> items = [];

  // Map<String, List<PubkeyMapping>> map;

  List<NotCoveredPubKey> notCoveredPubkeys = [];

  RelaySet(
      {
      required this.relayMinCountPerPubkey,
      required this.items,
      this.notCoveredPubkeys = const [],
      required this.direction});

// List<String> getRelaysForPubKey(String pubKey) {
//   List<String> relays = [];
//   for (MapEntry<String,List<PubkeyMapping>> entry in map.entries) {
//     if (entry.value.any((element) => element.pubKey == pubKey,)) {
//       relays.add(entry.key);
//     }
//   }
//   return relays;
// }
}

@embedded
class NotCoveredPubKey {
  String pubKey;
  int coverage;

  NotCoveredPubKey(this.pubKey, this.coverage);
}
