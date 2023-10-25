import 'package:dart_ndk/pubkey_mapping.dart';
import 'package:dart_ndk/read_write.dart';
import 'package:isar/isar.dart';

import '../nips/nip65/read_write_marker.dart';

part 'relay_set.g.dart';

@embedded
class RelaySetItem {
  String url;
  List<PubkeyMapping> pubKeyMappings;

  RelaySetItem(this.url, this.pubKeyMappings);
}

@collection
class RelaySet {
  String get id => buildId(name, pubKey);

  List<String> get urls => items.map((e) => e.url).toList();

  late String name;

  late String pubKey;

  int relayMinCountPerPubkey;

  RelayDirection direction;

  List<RelaySetItem> items = [];

  bool fallbackToBootstrapRelays=true;

  List<NotCoveredPubKey> notCoveredPubkeys = [];

  RelaySet(
      {
      required this.relayMinCountPerPubkey,
      required this.items,
      this.notCoveredPubkeys = const [],
      required this.direction});

  static buildId(String name, String pubKey) {
    return "$name,$pubKey";
  }
}

@embedded
class NotCoveredPubKey {
  String pubKey;
  int coverage;

  NotCoveredPubKey(this.pubKey, this.coverage);
}
