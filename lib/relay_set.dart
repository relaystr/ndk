import 'package:dart_ndk/pubkey_mapping.dart';
import 'package:dart_ndk/read_write.dart';

class RelaySet {
  int relayMinCountPerPubkey;

  RelayDirection direction;

  Map<String, List<PubkeyMapping>> map;

  Map<String,int> notCoveredPubkeys;

  RelaySet({required this.relayMinCountPerPubkey, required this.direction, required this.map,
    this.notCoveredPubkeys = const {}});

  List<String> getRelaysForPubKey(String pubKey) {
    List<String> relays = [];
    for (MapEntry<String,List<PubkeyMapping>> entry in map.entries) {
      if (entry.value.any((element) => element.pubKey == pubKey,)) {
        relays.add(entry.key);
      }
    }
    return relays;
  }
}