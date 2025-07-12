import 'package:ndk/domain_layer/entities/nip_05.dart';
import 'package:ndk/domain_layer/entities/pubkey_mapping.dart';
import 'package:ndk/domain_layer/entities/read_write_marker.dart';
import 'package:ndk/domain_layer/entities/user_relay_list.dart';
import 'package:ndk/ndk.dart';

// Extension for Nip01Event to add JSON serialization support
extension Nip01EventExtension on Nip01Event {
  Map<String, Object?> toJsonForStorage() {
    return {
      'id': id,
      'pubkey': pubKey,
      'created_at': createdAt,
      'kind': kind,
      'tags': tags,
      'content': content,
      'sig': sig,
      'validSig': validSig,
      'sources': sources,
    };
  }

  static Nip01Event fromJsonStorage(Map<String, Object?> json) {
    final event = Nip01Event.fromJson(json);
    
    // Restore additional properties not handled by fromJson
    if (json['validSig'] != null) {
      event.validSig = json['validSig'] as bool?;
    }
    
    if (json['sources'] != null) {
      event.sources = List<String>.from(json['sources'] as List);
    }
    
    return event;
  }
}

// Extension for ContactList to add JSON serialization support
extension ContactListExtension on ContactList {
  Map<String, Object?> toJsonForStorage() {
    return {
      'pubKey': pubKey,
      'contacts': contacts,
      'contactRelays': contactRelays,
      'petnames': petnames,
      'followedTags': followedTags,
      'followedCommunities': followedCommunities,
      'followedEvents': followedEvents,
      'createdAt': createdAt,
      'loadedTimestamp': loadedTimestamp,
      'sources': sources,
    };
  }

  static ContactList fromJsonStorage(Map<String, Object?> json) {
    final contactList = ContactList(
      pubKey: json['pubKey'] as String,
      contacts: List<String>.from(json['contacts'] as List),
    );
    
    contactList.contactRelays = List<String>.from(json['contactRelays'] as List);
    contactList.petnames = List<String>.from(json['petnames'] as List);
    contactList.followedTags = List<String>.from(json['followedTags'] as List);
    contactList.followedCommunities = List<String>.from(json['followedCommunities'] as List);
    contactList.followedEvents = List<String>.from(json['followedEvents'] as List);
    contactList.createdAt = json['createdAt'] as int;
    contactList.loadedTimestamp = json['loadedTimestamp'] as int?;
    contactList.sources = List<String>.from(json['sources'] as List);
    
    return contactList;
  }
}

// Extension for Metadata to add JSON serialization support
extension MetadataExtension on Metadata {
  Map<String, Object?> toJsonForStorage() {
    return {
      'pubKey': pubKey,
      'name': name,
      'displayName': displayName,
      'picture': picture,
      'banner': banner,
      'website': website,
      'about': about,
      'nip05': nip05,
      'lud16': lud16,
      'lud06': lud06,
      'updatedAt': updatedAt,
      'refreshedTimestamp': refreshedTimestamp,
      'sources': sources,
    };
  }

  static Metadata fromJsonStorage(Map<String, Object?> json) {
    final metadata = Metadata(
      pubKey: json['pubKey'] as String? ?? '',
      name: json['name'] as String?,
      displayName: json['displayName'] as String?,
      picture: json['picture'] as String?,
      banner: json['banner'] as String?,
      website: json['website'] as String?,
      about: json['about'] as String?,
      nip05: json['nip05'] as String?,
      lud16: json['lud16'] as String?,
      lud06: json['lud06'] as String?,
      updatedAt: json['updatedAt'] as int?,
      refreshedTimestamp: json['refreshedTimestamp'] as int?,
    );
    
    if (json['sources'] != null) {
      metadata.sources = List<String>.from(json['sources'] as List);
    }
    
    return metadata;
  }
}

// Extension for Nip05 to add JSON serialization support
extension Nip05Extension on Nip05 {
  Map<String, Object?> toJsonForStorage() {
    return {
      'pubKey': pubKey,
      'nip05': nip05,
      'valid': valid,
      'networkFetchTime': networkFetchTime,
      'relays': relays,
    };
  }

  static Nip05 fromJsonStorage(Map<String, Object?> json) {
    return Nip05(
      pubKey: json['pubKey'] as String,
      nip05: json['nip05'] as String,
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
      'relaysMap': relaysMap.map((key, value) => MapEntry(
        key, 
        value.map((mapping) => mapping.toJsonForStorage()).toList()
      )),
      'fallbackToBootstrapRelays': fallbackToBootstrapRelays,
      'notCoveredPubkeys': notCoveredPubkeys.map((pubkey) => {
        'pubKey': pubkey.pubKey,
        'coverage': pubkey.coverage,
      }).toList(),
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
    final notCoveredPubkeys = notCoveredJson.map((item) => NotCoveredPubKey(
      item['pubKey'] as String,
      item['coverage'] as int,
    )).toList();

    return RelaySet(
      name: json['name'] as String,
      pubKey: json['pubKey'] as String,
      relayMinCountPerPubkey: json['relayMinCountPerPubkey'] as int? ?? 0,
      direction: RelayDirection.values[json['direction'] as int? ?? 0],
      relaysMap: relaysMap,
      notCoveredPubkeys: notCoveredPubkeys,
      fallbackToBootstrapRelays: json['fallbackToBootstrapRelays'] as bool? ?? true,
    );
  }
}

// Extension for PubkeyMapping to add JSON serialization support
extension PubkeyMappingExtension on PubkeyMapping {
  Map<String, Object?> toJsonForStorage() {
    return {
      'pubKey': pubKey,
      'rwMarker': rwMarker.toJsonForStorage(),
    };
  }

  static PubkeyMapping fromJsonStorage(Map<String, Object?> json) {
    return PubkeyMapping(
      pubKey: json['pubKey'] as String,
      rwMarker: ReadWriteMarkerExtension.fromJsonStorage(json['rwMarker'] as Map<String, Object?>),
    );
  }
}

// Extension for ReadWriteMarker to add JSON serialization support
extension ReadWriteMarkerExtension on ReadWriteMarker {
  Map<String, Object?> toJsonForStorage() {
    return {
      'read': isRead,
      'write': isWrite,
    };
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
      'relays': relays.map((key, value) => MapEntry(key, value.toJsonForStorage())),
    };
  }

  static UserRelayList fromJsonStorage(Map<String, Object?> json) {
    // Reconstruct relays map
    final relaysJson = json['relays'] as Map<String, dynamic>? ?? {};
    final relays = <String, ReadWriteMarker>{};
    
    relaysJson.forEach((key, value) {
      relays[key] = ReadWriteMarkerExtension.fromJsonStorage(value as Map<String, Object?>);
    });

    return UserRelayList(
      pubKey: json['pubKey'] as String,
      createdAt: json['createdAt'] as int,
      refreshedTimestamp: json['refreshedTimestamp'] as int,
      relays: relays,
    );
  }
}

