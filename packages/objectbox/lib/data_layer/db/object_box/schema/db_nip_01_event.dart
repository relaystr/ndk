import 'package:ndk/entities.dart' as ndk_entities;
import 'package:objectbox/objectbox.dart';

@Entity()
class DbNip01Event {
  static const _sep = '\x1F';

  DbNip01Event({
    required this.pubKey,
    required this.kind,
    required this.content,
    required this.nostrId,
    int createdAt = 0,
  }) {
    this.createdAt = (createdAt == 0)
        ? DateTime.now().millisecondsSinceEpoch ~/ 1000
        : createdAt;
  }

  @Id()
  int dbId = 0;

  @Property()
  final String nostrId;

  @Property()
  final String pubKey;

  @Property()
  late int createdAt;

  @Property()
  final int kind;

  @Property()
  final String content;

  @Property()
  String? sig;

  @Property()
  bool? validSig;

  @Property()
  List<String> sources = [];

  /// Tags stored as packed strings using \x1F separator.
  /// Each element is a single tag joined: "p\x1Fabc" or "e\x1Fdef\x1F\x1Freply"
  @Property()
  List<String> tagsPacked = [];

  /// Searchable tag index: ["p:abc", "e:def", "t:nostr"]
  /// Stores "key:normalizedValue" pairs for querying by tag.
  //@Index()
  @Property()
  List<String> tagsIndex = [];

  @Transient()
  List<List<String>>? _cachedTags;

  @Transient()
  List<List<String>> get tags {
    _cachedTags ??= [for (final s in tagsPacked) s.split(_sep)];
    return _cachedTags!;
  }

  set tags(List<List<String>> value) {
    _cachedTags = value;
    tagsPacked = [for (final tag in value) tag.join(_sep)];
    tagsIndex = [
      for (final tag in value)
        if (tag.length >= 2 && tag[0].isNotEmpty && tag[1].isNotEmpty)
          '${tag[0]}:${tag[1].trim().toLowerCase()}'
    ];
  }

  @override
  bool operator ==(other) => other is DbNip01Event && nostrId == other.nostrId;

  @override
  int get hashCode => nostrId.hashCode;

  static int secondsSinceEpoch() {
    return DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }

  String? getEId() {
    for (var tag in tags) {
      if (tag.isNotEmpty && tag[0] == "e" && tag.length >= 2) {
        return tag[1];
      }
    }
    return null;
  }

  static List<String> getTagValues(List<List<String>> list, String tagKey) {
    return [
      for (final tag in list)
        if (tag.isNotEmpty && tag[0] == tagKey && tag.length >= 2)
          tag[1].trim().toLowerCase()
    ];
  }

  List<String> get tTags => getTagValues(tags, "t");

  List<String> get pTags => getTagValues(tags, "p");

  List<String> get replyETags => [
        for (final tag in tags)
          if (tag.isNotEmpty &&
              tag[0] == "e" &&
              tag.length >= 4 &&
              tag[3] == "reply")
            tag[1].trim().toLowerCase()
      ];

  String? getDtag() {
    for (var tag in tags) {
      if (tag.isNotEmpty && tag[0] == "d" && tag.length >= 2) {
        return tag[1];
      }
    }
    return null;
  }

  @override
  String toString() {
    return 'Nip01Event{pubKey: $pubKey, createdAt: $createdAt, kind: $kind, tags: $tags, content: $content, sources: $sources}';
  }

  ndk_entities.Nip01Event toNdk() {
    return ndk_entities.Nip01Event(
      pubKey: pubKey,
      content: content,
      createdAt: createdAt,
      kind: kind,
      tags: tags,
      id: nostrId,
      sig: sig,
      validSig: validSig,
      sources: sources,
    );
  }

  factory DbNip01Event.fromNdk(ndk_entities.Nip01Event ndkE) {
    final dbE = DbNip01Event(
      nostrId: ndkE.id,
      pubKey: ndkE.pubKey,
      content: ndkE.content,
      createdAt: ndkE.createdAt,
      kind: ndkE.kind,
    );
    dbE.tags = ndkE.tags;
    dbE.sig = ndkE.sig;
    dbE.validSig = ndkE.validSig;
    dbE.sources = ndkE.sources;
    return dbE;
  }
}
