import 'dart:convert';

import '../../domain_layer/entities/nip_01_event.dart';
import '../../shared/helpers/list_casting.dart';
import '../../shared/nips/nip19/nip19.dart';

/// Data model for NIP-01 Event
/// Extends [Nip01Event] entity with serialization methods to/from JSON and other formats
class Nip01EventModel extends Nip01Event {
  /// creates a new [Nip01EventModel] instance
  Nip01EventModel({
    required super.id,
    required super.pubKey,
    required super.createdAt,
    required super.kind,
    required super.tags,
    required super.content,
    required super.sig,
    super.validSig,
    super.sources = const [],
  });

  /// creates a copy of this event with the given fields replaced by the new values \
  /// needed so other packages depending on the extened nip01_event.dart can use copyWith
  @override
  Nip01EventModel copyWith({
    String? id,
    String? pubKey,
    int? createdAt,
    int? kind,
    List<List<String>>? tags,
    String? content,
    String? sig,
    bool? validSig,
    List<String>? sources,
  }) {
    return Nip01EventModel(
        id: id ?? this.id,
        pubKey: pubKey ?? this.pubKey,
        createdAt: createdAt ?? this.createdAt,
        kind: kind ?? this.kind,
        tags: tags ?? this.tags,
        content: content ?? this.content,
        sig: sig ?? this.sig,
        validSig: validSig ?? this.validSig,
        sources: sources ?? this.sources);
  }

  /**
   * encoding/decoding methods
   */

  /// creates a new [Nip01EventModel] instance from a [Nip01Event] entity
  factory Nip01EventModel.fromEntity(Nip01Event event) {
    return Nip01EventModel(
      id: event.id,
      pubKey: event.pubKey,
      createdAt: event.createdAt,
      kind: event.kind,
      tags: event.tags,
      content: event.content,
      sig: event.sig,
      sources: event.sources,
      validSig: event.validSig,
    );
  }

  /// creates a new [Nip01EventModel] instance from a JSON object
  factory Nip01EventModel.fromJson(Map<dynamic, dynamic> data) {
    final id = data['id'] as String? ?? '';
    final pubKey = data['pubkey'] as String? ?? '';
    final createdAt = data['created_at'] as int;
    final kind = data['kind'] as int;
    final tags = castToListOfListOfString(data['tags']);
    final content = data['content'] as String? ?? '';

    /// '' to support rumor events
    final sig = (data['sig'] as String?);

    return Nip01EventModel(
      id: id,
      pubKey: pubKey,
      createdAt: createdAt,
      kind: kind,
      tags: tags,
      content: content,
      sig: sig,
    );
  }

  /// Returns the Event object as a JSON object
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pubkey': pubKey,
      'created_at': createdAt,
      'kind': kind,
      'tags': tags,
      'content': content,
      'sig': sig
    };
  }

  /// Returns the Event object as a JSON string
  String toJsonString() {
    final jsonMap = toJson();
    return json.encode(jsonMap);
  }

  /// Encode this event as a nevent (NIP-19 event reference)
  ///
  /// Returns a bech32-encoded nevent string that includes:
  /// - Event ID (required)
  /// - Author pubkey (included)
  /// - Kind (included)
  /// - Relay hints from event.sources (if available)
  ///
  /// Usage: `final nevent = event.nevent;`
  String get nevent {
    return Nip19.encodeNevent(
      eventId: id,
      author: pubKey,
      kind: kind,
      relays: sources.isEmpty ? null : sources,
    );
  }

  /// Encode this event as an naddr (NIP-19 addressable event coordinate)
  ///
  /// Only works for addressable/replaceable events (kind >= 10000 or kind 0, 3, 41)
  /// Requires a "d" tag to identify the event.
  ///
  /// Returns a bech32-encoded naddr string or null if:
  /// - Event is not addressable/replaceable
  /// - Event doesn't have a "d" tag
  ///
  /// Usage: `final naddr = event.naddr;`
  String? get naddr {
    // Check if this is an addressable event
    if (!_isAddressableKind(kind)) {
      return null;
    }

    // Get the "d" tag identifier
    final identifier = getDtag();
    if (identifier == null) {
      return null;
    }

    return Nip19.encodeNaddr(
      identifier: identifier,
      pubkey: pubKey,
      kind: kind,
      relays: sources.isEmpty ? null : sources,
    );
  }

  /// Returns the Event object as a base64-encoded JSON string
  String toBase64() {
    return base64Encode(utf8.encode(json.encode(toJson())));
  }

  /// Check if an event kind is addressable/replaceable
  ///
  /// According to NIP-01:
  /// - Replaceable events: 0, 3, 41
  /// - Parameterized replaceable events: 10000-19999, 30000-39999
  bool _isAddressableKind(int kind) {
    // Replaceable events
    if (kind == 0 || kind == 3 || kind == 41) {
      return true;
    }

    // Parameterized replaceable events
    if ((kind >= 10000 && kind <= 19999) || (kind >= 30000 && kind <= 39999)) {
      return true;
    }

    return false;
  }
}
