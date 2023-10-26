import 'package:collection/collection.dart';
import 'package:dart_ndk/models/pubkey_mapping.dart';
import 'package:dart_ndk/read_write.dart';

import '../nips/nip01/filter.dart';

class RelaySet {
  String get id => buildId(name, pubKey);

  Iterable<String> get urls => relaysMap.keys;

  late String name;

  late String pubKey;

  int relayMinCountPerPubkey;

  RelayDirection direction;

  // relay url -> covered pubKeys
  Map<String,List<PubkeyMapping>> relaysMap = {};

  bool fallbackToBootstrapRelays = true;

  List<NotCoveredPubKey> notCoveredPubkeys = [];

  RelaySet({
    required this.name,
    required this.pubKey,
    this.relayMinCountPerPubkey = 0,
    required this.relaysMap,
    this.notCoveredPubkeys = const [],
    required this.direction,
    this.fallbackToBootstrapRelays = true
  });

  static buildId(String name, String pubKey) {
    return "$name,$pubKey";
  }

  static const int MAX_AUTHORS_PER_REQUEST = 100;

  List<RelayRequest> splitIntoRequests(Filter filter) {
    List<RelayRequest> requests = [];
    for (var entry in relaysMap.entries) {
      String url = entry.key;
      List<PubkeyMapping> pubKeyMappings = entry.value;
      if (pubKeyMappings.isEmpty) {
        requests.add(RelayRequest(url, filter));
      } else if (filter.authors != null && filter.authors!.isNotEmpty && direction == RelayDirection.outbox) {
        List<String> pubKeysForRelay = [];
        for (String pubKey in filter.authors!) {
          if (pubKeyMappings.any((pubKeyMapping) => pubKey == pubKeyMapping.pubKey || notCoveredPubkeys.any((element) => element.pubKey == pubKey))) {
            pubKeysForRelay.add(pubKey);
          }
        }
        if (pubKeysForRelay.isNotEmpty) {
          requests.addAll(sliceFilterAuthors(filter.cloneWithAuthors(pubKeysForRelay), url));
        }
      } else if (filter.pTags != null && filter.pTags!.isNotEmpty && direction == RelayDirection.inbox) {
        List<String> pubKeysForRelay = [];
        for (String pubKey in filter.pTags!) {
          if (pubKeyMappings.any((pubKeyMapping) => pubKey == pubKeyMapping.pubKey || notCoveredPubkeys.any((element) => element.pubKey == pubKey))) {
            pubKeysForRelay.add(pubKey);
          }
        }
        if (pubKeysForRelay.isNotEmpty) {
          requests.addAll(sliceFilterAuthors(filter.cloneWithPTags(pubKeysForRelay), url));
        }
      } else if (filter.eTags != null && direction == RelayDirection.inbox) {
        requests.add(RelayRequest(url, filter));
      } else {
        /// TODO ????
      }
    }
    return requests;
  }

  static List<RelayRequest> sliceFilterAuthors(Filter filter, String url) {
    if (filter.authors != null && filter.authors!.length > MAX_AUTHORS_PER_REQUEST) {
      return filter.authors!.slices(MAX_AUTHORS_PER_REQUEST).map((slice) => RelayRequest(url, filter.cloneWithAuthors(slice))).toList();
    } else {
      return [RelayRequest(url, filter)];
    }
  }

  void addMoreRelays(Map<String,List<PubkeyMapping>> more) {
    more.forEach((key, value) {
      if (!relaysMap.keys.contains(key)) {
        relaysMap[key] = value;
      }
    });
  }
}

class RelayRequest {
  String url;
  Filter filter;

  RelayRequest(this.url, this.filter);
}

class NotCoveredPubKey {
  String pubKey;
  int coverage;

  NotCoveredPubKey(this.pubKey, this.coverage);
}


