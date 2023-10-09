import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dart_ndk/bip340.dart';

class Event {
  /// Creates a new Nostr event.
  ///
  /// [pubKey] is the author's public key.
  /// [kind] is the event kind.
  /// [tags] is a JSON object of event tags.
  /// [content] is an arbitrary string.
  ///
  /// Nostr event `id` and `created_at` fields are calculated automatically.
  ///
  Event(this.pubKey, this.kind, this.tags, this.content,
      {int? publishAt}) {
    if (publishAt != null) {
      createdAt = publishAt;
    } else {
      createdAt = _secondsSinceEpoch();
    }
    id = _calculateId(pubKey, createdAt, kind, tags, content);
  }

  Event._(this.id, this.pubKey, this.createdAt, this.kind, this.tags,
      this.content, this.sig);

  factory Event.fromJson(Map<String, dynamic> data) {
    final id = data['id'] as String;
    final pubKey = data['pubkey'] as String;
    final createdAt = data['created_at'] as int;
    final kind = data['kind'] as int;
    final tags = data['tags'];
    final content = data['content'] as String;
    final sig = data['sig'] as String;

    return Event._(id, pubKey, createdAt, kind, tags, content, sig);
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
  List<dynamic> tags; // Modified by proof-of-work

  /// Event content.
  final String content;

  /// 64-byte Schnorr signature of [Event.id].
  String sig = '';

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

  void sign(String privateKey) {
    sig = Bip340.sign(id, privateKey);
  }

  bool get isValid {
    // Validate event data
    if (id != _calculateId(pubKey, createdAt, kind, tags, content)) {
      return false;
    }
    return true;
  }

  // Individual events with the same "id" are equivalent
  @override
  bool operator ==(other) => other is Event && id == other.id;
  @override
  int get hashCode => id.hashCode;

  static int _secondsSinceEpoch() {
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
}
