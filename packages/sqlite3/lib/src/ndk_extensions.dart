import 'package:ndk/entities.dart';

// Extension for Nip05 to add JSON serialization support
extension Nip05Extension on Nip05 {
  Map<String, Object?> toJsonForStorage() {
    return {
      'pubKey': pubKey,
      'nip05': identifier,
      'valid': valid,
      'networkFetchTime': networkFetchTime,
      'relays': relays,
    };
  }

  static Nip05 fromJsonStorage(Map<String, Object?> json) {
    return Nip05(
      pubKey: json['pubKey'] as String?,
      identifier: json['nip05'] as String,
      valid: json['valid'] as bool? ?? false,
      networkFetchTime: json['networkFetchTime'] as int?,
      relays: json['relays'] != null
          ? List<String>.from(json['relays'] as List)
          : const [],
    );
  }
}

// Extension for RelaySet to add JSON serialization support
extension RelaySetExtension on RelaySet {
  Map<String, Object?> toJsonForStorage() {
    return {
      'name': name,
      'pubKey': pubKey,
      'relayMinCountPerPubkey': relayMinCountPerPubkey,
      'direction': direction.index,
      'relaysMap': relaysMap.map(
        (key, value) => MapEntry(
          key,
          value.map((mapping) => mapping.toJsonForStorage()).toList(),
        ),
      ),
      'fallbackToBootstrapRelays': fallbackToBootstrapRelays,
      'notCoveredPubkeys': notCoveredPubkeys
          .map(
            (pubkey) => {'pubKey': pubkey.pubKey, 'coverage': pubkey.coverage},
          )
          .toList(),
    };
  }

  static RelaySet fromJsonStorage(Map<String, Object?> json) {
    // Reconstruct relaysMap
    final relaysMapJson = json['relaysMap'] as Map<String, dynamic>? ?? {};
    final relaysMap = <String, List<PubkeyMapping>>{};

    relaysMapJson.forEach((key, value) {
      final mappings = (value as List)
          .map((mapping) => PubkeyMappingExtension.fromJsonStorage(mapping))
          .toList();
      relaysMap[key] = mappings;
    });

    // Reconstruct notCoveredPubkeys
    final notCoveredJson = json['notCoveredPubkeys'] as List? ?? [];
    final notCoveredPubkeys = notCoveredJson
        .map(
          (item) => NotCoveredPubKey(
            item['pubKey'] as String,
            item['coverage'] as int,
          ),
        )
        .toList();

    return RelaySet(
      name: json['name'] as String,
      pubKey: json['pubKey'] as String,
      relayMinCountPerPubkey: json['relayMinCountPerPubkey'] as int? ?? 0,
      direction: RelayDirection.values[json['direction'] as int? ?? 0],
      relaysMap: relaysMap,
      notCoveredPubkeys: notCoveredPubkeys,
      fallbackToBootstrapRelays:
          json['fallbackToBootstrapRelays'] as bool? ?? true,
    );
  }
}

// Extension for PubkeyMapping to add JSON serialization support
extension PubkeyMappingExtension on PubkeyMapping {
  Map<String, Object?> toJsonForStorage() {
    return {'pubKey': pubKey, 'rwMarker': rwMarker.toJsonForStorage()};
  }

  static PubkeyMapping fromJsonStorage(Map<String, Object?> json) {
    return PubkeyMapping(
      pubKey: json['pubKey'] as String,
      rwMarker: ReadWriteMarkerExtension.fromJsonStorage(
        json['rwMarker'] as Map<String, Object?>,
      ),
    );
  }
}

// Extension for ReadWriteMarker to add JSON serialization support
extension ReadWriteMarkerExtension on ReadWriteMarker {
  Map<String, Object?> toJsonForStorage() {
    return {'read': isRead, 'write': isWrite};
  }

  static ReadWriteMarker fromJsonStorage(Map<String, Object?> json) {
    final read = json['read'] as bool? ?? false;
    final write = json['write'] as bool? ?? false;

    return ReadWriteMarker.from(read: read, write: write);
  }
}

// Extension for UserRelayList to add JSON serialization support
extension UserRelayListExtension on UserRelayList {
  Map<String, Object?> toJsonForStorage() {
    return {
      'pubKey': pubKey,
      'createdAt': createdAt,
      'refreshedTimestamp': refreshedTimestamp,
      'relays': relays.map(
        (key, value) => MapEntry(key, value.toJsonForStorage()),
      ),
    };
  }

  static UserRelayList fromJsonStorage(Map<String, Object?> json) {
    // Reconstruct relays map
    final relaysJson = json['relays'] as Map<String, dynamic>? ?? {};
    final relays = <String, ReadWriteMarker>{};

    relaysJson.forEach((key, value) {
      relays[key] = ReadWriteMarkerExtension.fromJsonStorage(
        value as Map<String, Object?>,
      );
    });

    return UserRelayList(
      pubKey: json['pubKey'] as String,
      createdAt: json['createdAt'] as int,
      refreshedTimestamp: json['refreshedTimestamp'] as int,
      relays: relays,
    );
  }
}

// Extension for CahsuKeyset to add JSON serialization support
extension CahsuKeysetExtension on CahsuKeyset {
  Map<String, Object?> toJsonForStorage() {
    return {
      'id': id,
      'mintUrl': mintUrl,
      'unit': unit,
      'active': active,
      'inputFeePPK': inputFeePPK,
      'mintKeyPairs': mintKeyPairs
          .map((pair) => {'amount': pair.amount, 'pubkey': pair.pubkey})
          .toList(),
      'fetchedAt': fetchedAt,
    };
  }

  static CahsuKeyset fromJsonStorage(Map<String, Object?> json) {
    return CahsuKeyset(
      id: json['id'] as String,
      mintUrl: json['mintUrl'] as String,
      unit: json['unit'] as String,
      active: json['active'] as bool,
      inputFeePPK: json['inputFeePPK'] as int,
      mintKeyPairs: (json['mintKeyPairs'] as List<dynamic>)
          .map(
            (e) => CahsuMintKeyPair(
              amount: e['amount'] as int,
              pubkey: e['pubkey'] as String,
            ),
          )
          .toSet(),
      fetchedAt: json['fetchedAt'] as int?,
    );
  }
}

// Extension for CashuMintInfo to add JSON serialization support
extension CashuMintInfoExtension on CashuMintInfo {
  Map<String, Object?> toJsonForStorage() {
    return {
      'name': name,
      'pubkey': pubkey,
      'version': version,
      'description': description,
      'description_long': descriptionLong,
      'contact': contact.map((c) => c.toJson()).toList(),
      'motd': motd,
      'icon_url': iconUrl,
      'urls': urls,
      'time': time,
      'tos_url': tosUrl,
      'nuts': nuts.map((k, v) => MapEntry(k.toString(), v.toJson())),
    };
  }

  static CashuMintInfo fromJsonStorage(Map<String, Object?> json) {
    final nutsJson = (json['nuts'] as Map?) ?? {};
    final parsedNuts = <int, CashuMintNut>{};
    nutsJson.forEach((k, v) {
      final key = int.tryParse(k.toString());
      if (key != null) {
        try {
          if (v is List) {
            return; // skip non-spec compliant entries
          }
          parsedNuts[key] = CashuMintNut.fromJson(
            (v ?? {}) as Map<String, dynamic>,
          );
        } catch (e) {
          // skip entries that fail to parse
        }
      }
    });

    return CashuMintInfo(
      name: json['name'] as String?,
      pubkey: json['pubkey'] as String?,
      version: json['version'] as String?,
      description: json['description'] as String?,
      descriptionLong: json['description_long'] as String?,
      contact: ((json['contact'] as List?) ?? const [])
          .map((e) => CashuMintContact.fromJson(e as Map<String, dynamic>))
          .toList(),
      motd: json['motd'] as String?,
      iconUrl: json['icon_url'] as String?,
      urls: List<String>.from(json['urls'] as List? ?? []),
      time: (json['time'] is num) ? (json['time'] as num).toInt() : null,
      tosUrl: json['tos_url'] as String?,
      nuts: parsedNuts,
    );
  }
}
