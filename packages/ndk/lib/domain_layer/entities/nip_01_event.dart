import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../shared/helpers/list_casting.dart';
import '../../shared/nips/nip01/bip340.dart';
import '../../shared/nips/nip13/nip13.dart';
import '../../shared/nips/nip19/nip19.dart';

/// basic nostr nip01 event data structure
class Nip01Event {
  static const int kTextNodeKind = 1;

  /// Creates a new Nostr event.
  ///
  /// [pubKey] is the author's public key.
  /// [kind] is the event kind.
  /// [tags] is a JSON object of event tags.
  /// [content] is an arbitrary string.
  ///
  /// Nostr event `id` and `created_at` fields are calculated automatically.
  ///
  Nip01Event({
    required this.pubKey,
    required this.kind,
    required this.tags,
    required this.content,
    int createdAt = 0,
  }) {
    this.createdAt = (createdAt == 0)
        ? DateTime.now().millisecondsSinceEpoch ~/ 1000
        : createdAt;
    id = _calculateId(pubKey, this.createdAt, kind, tags, content);
  }

  Nip01Event._(
    this.id,
    this.pubKey,
    this.createdAt,
    this.kind,
    this.tags,
    this.content,
    this.sig,
  );

  factory Nip01Event.fromJson(Map<dynamic, dynamic> data) {
    final id = data['id'] as String? ?? '';
    final pubKey = data['pubkey'] as String? ?? '';
    final createdAt = data['created_at'] as int;
    final kind = data['kind'] as int;
    final tags = castToListOfListOfString(data['tags']);
    final content = data['content'] as String? ?? '';

    /// '' to support rumor events
    final sig = (data['sig'] as String?) ?? '';

    return Nip01Event._(id, pubKey, createdAt, kind, tags, content, sig);
  }

  /// The event ID is a 32-byte SHA256 hash of the serialised event data.
  String id = '';

  /// The event author's public key.
  final String pubKey;

  /// Event creation timestamp in Unix time.
  late int createdAt;

  /// Event kind identifier (e.g. text_note, set_metadata, etc).
  final int kind;

  /// A JSON array of event tags.
  List<List<String>> tags; // Modified by proof-of-work

  /// Event content.
  String content;

  /// 64-byte Schnorr signature of [Nip01Event.id].
  String sig = '';

  /// has signature been validated?
  bool? validSig;

  /// Relay that an event was received from
  List<String> sources = [];

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

  /// Returns the Event object as a base64-encoded JSON string
  String toBase64() {
    return base64Encode(utf8.encode(json.encode(toJson())));
  }

  /// sign the event with given privateKey
  /// [WARN] only for testing! Use [EventSigner] to sign events in production
  void sign(String privateKey) {
    sig = Bip340.sign(id, privateKey);
  }

  /// is Id valid?
  bool get isIdValid {
    // Validate event data
    if (id != _calculateId(pubKey, createdAt, kind, tags, content)) {
      return false;
    }
    // Validate proof of work if present
    if (!Nip13.validateEvent(this)) {
      return false;
    }
    return true;
  }

  // Individual events with the same "id" are equivalent
  @override
  bool operator ==(other) => other is Nip01Event && id == other.id;
  @override
  int get hashCode => id.hashCode;

  /// seconds since epoch
  static int secondsSinceEpoch() {
    final secondsSinceEpoch = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return secondsSinceEpoch;
  }

  static String _calculateId(String publicKey, int createdAt, int kind,
      List<dynamic> tags, String content) {
    final jsonData =
        json.encode([0, publicKey, createdAt, kind, tags, content]);
    final bytes = utf8.encode(jsonData);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// return first `e` tag found
  String? getEId() {
    return getFirstTag("e");
  }

  /// return all tags that match given `tag` e.g. 'p'
  List<String> getTags(String tag) {
    List<String> foundTags = [];
    for (final e in tags) {
      if (e.length > 1) {
        final key = e[0];
        final value = e[1];

        if (key == tag) {
          foundTags.add(value.toString().trim().toLowerCase());
        }
      }
    }
    return foundTags;
  }

  /// return all `t` tags in event
  List<String> get tTags {
    return getTags("t");
  }

  /// return all `p` tags in event
  List<String> get pTags {
    return getTags("p");
  }

  /// return all e tags in event that have a `reply` marker
  List<String> get replyETags {
    List<String> replyIds = [];
    for (final tag in tags) {
      if (tag.length >= 4) {
        final key = tag[0];
        final value = tag[1];
        final marker = tag[3];

        if (key == "e" && marker == "reply") {
          replyIds.add(value.toString().trim().toLowerCase());
        }
      }
    }
    return replyIds;
  }

  /// return first found `d` tag
  String? getDtag() {
    return getFirstTag("d");
  }

  /// Get first tag matching given name
  String? getFirstTag(String name) {
    for (final tag in tags) {
      if (tag.length > 1) {
        final key = tag[0];
        final value = tag[1];

        if (key == name) {
          return value;
        }
      }
    }
    return null;
  }

  @override
  String toString() {
    return 'Nip01Event{pubKey: $pubKey, createdAt: $createdAt, kind: $kind, tags: $tags, content: $content, sources: $sources}';
  }

  Nip01Event copyWith({
    String? pubKey,
    int? createdAt,
    int? kind,
    List<List<String>>? tags,
    String? content,
    String? sig,
    List<String>? sources,
  }) {
    final event = Nip01Event(
      pubKey: pubKey ?? this.pubKey,
      createdAt: createdAt ?? this.createdAt,
      kind: kind ?? this.kind,
      tags: tags ?? this.tags,
      content: content ?? this.content,
    );
    event.sig = sig ?? this.sig;
    event.sources = sources ?? this.sources;
    return event;
  }

  /// Mine this event with proof of work
  Nip01Event minePoW(int targetDifficulty, {int? maxIterations}) {
    return Nip13.mineEvent(this, targetDifficulty,
        maxIterations: maxIterations);
  }

  /// Get the proof of work difficulty of this event
  int get powDifficulty => Nip13.getDifficulty(id);

  /// Check if this event meets a specific difficulty target
  bool checkPoWDifficulty(int targetDifficulty) {
    return Nip13.checkDifficulty(id, targetDifficulty);
  }

  /// Get the target difficulty from nonce tag if present
  int? get targetPoWDifficulty => Nip13.getTargetDifficultyFromEvent(this);

  /// Calculate the commitment (work done) for this event
  int get powCommitment => Nip13.calculateCommitment(id);

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
