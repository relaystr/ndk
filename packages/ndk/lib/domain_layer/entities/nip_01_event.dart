import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../shared/helpers/list_casting.dart';
import '../../shared/nips/nip01/bip340.dart';

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
    final id = data['id'] as String;
    final pubKey = data['pubkey'] as String;
    final createdAt = data['created_at'] as int;
    final kind = data['kind'] as int;
    final tags = castToListOfListOfString(data['tags']);
    final content = data['content'] as String;
    final sig = data['sig'] as String;

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

  /// Recalculate the event ID based on the current event data.
  void recalculateId() {
    id = _calculateId(pubKey, createdAt, kind, tags, content);
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
    final copy = Nip01Event._(
      id,
      pubKey ?? this.pubKey,
      createdAt ?? this.createdAt,
      kind ?? this.kind,
      tags ?? this.tags,
      content ?? this.content,
      sig ?? this.sig,
    )..sources = sources ?? this.sources;
    final newId = _calculateId(
        copy.pubKey, copy.createdAt, copy.kind, copy.tags, copy.content);
    copy.id = newId;
    return copy;
  }
}
