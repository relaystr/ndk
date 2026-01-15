import 'dart:convert';
import 'package:ndk/entities.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class DbRelaySet {
  @Id()
  int dbId = 0;

  /// Unique identifier: name + pubKey
  @Property()
  @Unique()
  String id;

  @Property()
  String name;

  @Property()
  String pubKey;

  @Property()
  int relayMinCountPerPubkey;

  /// Stored as string: 'inbox' or 'outbox'
  @Property()
  String direction;

  /// JSON encoded map of relay URL -> list of pubkey mappings
  @Property()
  String relaysMapJson;

  @Property()
  bool fallbackToBootstrapRelays;

  DbRelaySet({
    required this.id,
    required this.name,
    required this.pubKey,
    required this.relayMinCountPerPubkey,
    required this.direction,
    required this.relaysMapJson,
    this.fallbackToBootstrapRelays = true,
  });

  /// Convert from NDK RelaySet to DbRelaySet
  static DbRelaySet fromNdk(RelaySet relaySet) {
    return DbRelaySet(
      id: RelaySet.buildId(relaySet.name, relaySet.pubKey),
      name: relaySet.name,
      pubKey: relaySet.pubKey,
      relayMinCountPerPubkey: relaySet.relayMinCountPerPubkey,
      direction: relaySet.direction.name,
      relaysMapJson: _encodeRelaysMap(relaySet.relaysMap),
      fallbackToBootstrapRelays: relaySet.fallbackToBootstrapRelays,
    );
  }

  /// Convert to NDK RelaySet
  RelaySet toNdk() {
    return RelaySet(
      name: name,
      pubKey: pubKey,
      relayMinCountPerPubkey: relayMinCountPerPubkey,
      direction: _parseDirection(direction),
      relaysMap: _decodeRelaysMap(relaysMapJson),
      fallbackToBootstrapRelays: fallbackToBootstrapRelays,
    );
  }

  /// Encode relaysMap to JSON string
  static String _encodeRelaysMap(Map<String, List<PubkeyMapping>> relaysMap) {
    final Map<String, List<Map<String, String>>> encoded = {};
    relaysMap.forEach((url, mappings) {
      encoded[url] = mappings
          .map((m) => {
                'pubKey': m.pubKey,
                'rwMarker': m.rwMarker.name,
              })
          .toList();
    });
    return json.encode(encoded);
  }

  /// Decode JSON string to relaysMap
  static Map<String, List<PubkeyMapping>> _decodeRelaysMap(String jsonStr) {
    if (jsonStr.isEmpty) return {};

    final Map<String, dynamic> decoded = json.decode(jsonStr);
    final Map<String, List<PubkeyMapping>> result = {};

    decoded.forEach((url, mappingsJson) {
      final List<dynamic> mappingsList = mappingsJson as List<dynamic>;
      result[url] = mappingsList.map((m) {
        final map = m as Map<String, dynamic>;
        return PubkeyMapping(
          pubKey: map['pubKey'] as String,
          rwMarker: _parseReadWriteMarker(map['rwMarker'] as String),
        );
      }).toList();
    });

    return result;
  }

  /// Parse direction string to RelayDirection enum
  static RelayDirection _parseDirection(String directionStr) {
    if (directionStr == RelayDirection.inbox.name) {
      return RelayDirection.inbox;
    }
    return RelayDirection.outbox;
  }

  /// Parse marker string to ReadWriteMarker enum
  static ReadWriteMarker _parseReadWriteMarker(String markerStr) {
    if (markerStr == ReadWriteMarker.readOnly.name) {
      return ReadWriteMarker.readOnly;
    } else if (markerStr == ReadWriteMarker.writeOnly.name) {
      return ReadWriteMarker.writeOnly;
    }
    return ReadWriteMarker.readWrite;
  }
}
