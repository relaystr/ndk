import 'package:ndk/domain_layer/entities/nip_01_utils.dart';

/// basic nostr nip01 event data structure
class Nip01Event {
  static const int kTextNodeKind = 1;

  /// The event ID is a 32-byte SHA256 hash of the serialised event data.
  late final String id;

  /// The event author's public key.
  final String pubKey;

  /// Event creation timestamp in Unix time.
  late final int createdAt;

  /// Event kind identifier (e.g. text_note, set_metadata, etc).
  final int kind;

  /// A JSON array of event tags.
  final List<List<String>> tags; // Modified by proof-of-work

  /// Event content.
  final String content;

  /// 64-byte Schnorr signature of [Nip01Event.id].
  final String? sig;

  /// has signature been validated?
  final bool? validSig;

  /// Relay that an event was received from
  final List<String> sources;

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
    String? id,
    required this.pubKey,
    required this.kind,
    required this.tags,
    required this.content,
    this.sig,
    this.validSig,
    this.sources = const [],
    int createdAt = 0,
  }) {
    this.createdAt = (createdAt == 0)
        ? DateTime.now().millisecondsSinceEpoch ~/ 1000
        : createdAt;
    this.id = id ??
        Nip01Utils.calculateEventIdSync(
            pubKey: pubKey,
            createdAt: createdAt,
            kind: kind,
            tags: tags,
            content: content);
  }

  Nip01Event copyWith({
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
    return Nip01Event(
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
}
