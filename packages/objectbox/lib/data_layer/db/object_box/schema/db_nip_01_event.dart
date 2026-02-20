import 'package:ndk/entities.dart' as ndk_entities;
import 'package:objectbox/objectbox.dart';

@Entity()
class DbNip01Event {
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

  @Backlink('event')
  final tags = ToMany<DbTag>();

  @override
  bool operator ==(other) => other is DbNip01Event && nostrId == other.nostrId;

  @override
  int get hashCode => nostrId.hashCode;

  static int secondsSinceEpoch() {
    return DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }

  String? getEId() {
    for (var tag in tags) {
      if (tag.key == "e") {
        return tag.value;
      }
    }
    return null;
  }

  static List<String> getTags(List<DbTag> list, String tagKey) {
    final result = <String>[];
    for (final tag in list) {
      if (tag.key == tagKey) {
        result.add(tag.normalizedValue);
      }
    }
    return result;
  }

  List<String> get tTags {
    return getTags(tags, "t");
  }

  List<String> get pTags {
    return getTags(tags, "p");
  }

  List<String> get replyETags {
    final result = <String>[];
    for (final tag in tags) {
      if (tag.key == "e" && tag.marker == "reply") {
        result.add(tag.normalizedValue);
      }
    }
    return result;
  }

  String? getDtag() {
    for (var tag in tags) {
      if (tag.key == "d") {
        return tag.value;
      }
    }
    return null;
  }

  @override
  String toString() {
    return 'Nip01Event{pubKey: $pubKey, createdAt: $createdAt, kind: $kind, tags: $tags, content: $content, sources: $sources}';
  }

  ndk_entities.Nip01Event toNdk() {
    final ndkE = ndk_entities.Nip01Event(
      pubKey: pubKey,
      content: content,
      createdAt: createdAt,
      kind: kind,
      tags: _tagsToList(tags),
      id: nostrId,
      sig: sig,
      validSig: validSig,
      sources: sources,
    );

    return ndkE;
  }

  factory DbNip01Event.fromNdk(ndk_entities.Nip01Event ndkE) {
    final dbE = DbNip01Event(
      nostrId: ndkE.id,
      pubKey: ndkE.pubKey,
      content: ndkE.content,
      createdAt: ndkE.createdAt,
      kind: ndkE.kind,
    );

    dbE.tags.addAll(_listToTags(ndkE.tags));
    dbE.sig = ndkE.sig;
    dbE.validSig = ndkE.validSig;
    dbE.sources = ndkE.sources;
    return dbE;
  }

  static List<List<String>> _tagsToList(Iterable<DbTag> tags) {
    final result = <List<String>>[];
    for (final tag in tags) {
      result.add(tag.toList());
    }
    return result;
  }

  static List<DbTag> _listToTags(List<List<String>> list) {
    final result = <DbTag>[];
    for (final tagList in list) {
      result.add(DbTag.fromList(tagList));
    }
    return result;
  }
}

@Entity()
class DbTag {
  @Id()
  int id = 0;

  @Property()
  String key;

  @Property()
  String value;

  @Property()
  String? marker;

  @Index()
  @Property()
  String normalizedValue;

  /// Store all elements of the tag to preserve full tag data
  @Property()
  List<String> elements;

  final event = ToOne<DbNip01Event>();

  DbTag(
      {this.key = '',
      this.value = '',
      this.marker,
      this.elements = const [],
      String? normalizedValue})
      : normalizedValue = normalizedValue ?? value.trim().toLowerCase();

  List<String> toList() {
    // Return the full elements if available, otherwise construct from key/value/marker
    if (elements.isNotEmpty) {
      return elements;
    }
    return marker != null ? [key, value, '', marker!] : [key, value];
  }

  static DbTag fromList(List<String> list) {
    return DbTag(
      key: list.isNotEmpty ? list[0] : '',
      value: list.length >= 2 ? list[1] : '',
      marker: list.length >= 4 ? list[3] : null,
      elements: list,
    );
  }
}
