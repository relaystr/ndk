import 'package:collection/collection.dart';
import 'package:dart_ndk/pubkey_mapping.dart';
import 'package:dart_ndk/read_write.dart';
import 'package:isar/isar.dart';

import '../nips/nip01/filter.dart' as NostrFilter;
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

  bool fallbackToBootstrapRelays = true;

  List<NotCoveredPubKey> notCoveredPubkeys = [];

  RelaySet({
    required this.relayMinCountPerPubkey,
    required this.items,
    this.notCoveredPubkeys = const [],
    required this.direction,
    this.fallbackToBootstrapRelays = true
  });

  static buildId(String name, String pubKey) {
    return "$name,$pubKey";
  }

  static const int MAX_AUTHORS_PER_REQUEST = 100;

  List<RelayRequest> splitIntoRequests(NostrFilter.Filter filter) {
    List<RelayRequest> requests = [];
    for (var item in items) {
      if (item.pubKeyMappings.isEmpty) {
        requests.add(RelayRequest(item.url, filter));
      } else if (filter.authors != null && filter.authors!.isNotEmpty && direction == RelayDirection.outbox) {
        List<String> pubKeysForRelay = [];
        for (String pubKey in filter.authors!) {
          if (item.pubKeyMappings.any((pubKeyMapping) => pubKey == pubKeyMapping.pubKey || notCoveredPubkeys.any((element) => element.pubKey == pubKey))) {
            pubKeysForRelay.add(pubKey);
          }
        }
        if (pubKeysForRelay.isNotEmpty) {
          requests.addAll(sliceFilterAuthors(filter.cloneWithAuthors(pubKeysForRelay), item.url));
        }
      } else if (filter.pTags != null && filter.pTags!.isNotEmpty && direction == RelayDirection.inbox) {
        List<String> pubKeysForRelay = [];
        for (String pubKey in filter.pTags!) {
          if (item.pubKeyMappings.any((pubKeyMapping) => pubKey == pubKeyMapping.pubKey || notCoveredPubkeys.any((element) => element.pubKey == pubKey))) {
            pubKeysForRelay.add(pubKey);
          }
        }
        if (pubKeysForRelay.isNotEmpty) {
          requests.addAll(sliceFilterAuthors(filter.cloneWithPTags(pubKeysForRelay), item.url));
        }
      } else if (filter.eTags != null && direction == RelayDirection.inbox) {
        requests.add(RelayRequest(item.url, filter));
      } else {
        /// TODO ????
      }
    }
    return requests;
  }

  static List<RelayRequest> sliceFilterAuthors(NostrFilter.Filter filter, String url) {
    if (filter.authors != null && filter.authors!.length > MAX_AUTHORS_PER_REQUEST) {
      return filter.authors!.slices(MAX_AUTHORS_PER_REQUEST).map((slice) => RelayRequest(url, filter.cloneWithAuthors(slice))).toList();
    } else {
      return [RelayRequest(url, filter)];
    }
  }

}

class RelayRequest {
  String url;
  NostrFilter.Filter filter;

  RelayRequest(this.url, this.filter);
}

@embedded
class NotCoveredPubKey {
  String pubKey;
  int coverage;

  NotCoveredPubKey(this.pubKey, this.coverage);
}
