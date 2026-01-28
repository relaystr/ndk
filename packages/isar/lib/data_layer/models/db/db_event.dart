// ignore_for_file: unnecessary_overrides

import 'dart:convert';

import 'package:isar/isar.dart';
import 'package:ndk/ndk.dart';

part 'db_event.g.dart';

/// Helper to decode tags from JSON string
List<List<String>> _decodeTags(String? json) {
  if (json == null || json.isEmpty) return [];
  try {
    final decoded = jsonDecode(json) as List;
    return decoded
        .map((e) => (e as List).map((item) => item.toString()).toList())
        .toList();
  } catch (_) {
    return [];
  }
}

@Collection(inheritance: false)
class DbEvent extends Nip01Event {
  @override
  String get id => super.id;

  @override
  String get pubKey => super.pubKey;

  @override
  int get kind => super.kind;

  @override
  int get createdAt => super.createdAt;

  @ignore
  @override
  List<List<String>> get tags => super.tags;

  /// Tags stored as JSON string for Isar (Isar doesn't support List<List<String>>)
  final String tagsJson;

  @override
  String get content => super.content;

  @override
  String? get sig => super.sig;

  @override
  bool? get validSig => super.validSig;

  @override
  List<String> get sources => super.sources;

  /// Constructor used by Isar - takes tagsJson and decodes it
  DbEvent({
    required String id,
    required String pubKey,
    required int kind,
    required this.tagsJson,
    required String content,
    int createdAt = 0,
    String? sig,
    bool? validSig,
    List<String> sources = const [],
  }) : super(
          id: id,
          pubKey: pubKey,
          kind: kind,
          tags: _decodeTags(tagsJson),
          content: content,
          createdAt: createdAt,
          sig: sig,
          validSig: validSig,
          sources: sources,
        );

  /// Factory to create DbEvent from Nip01Event
  static DbEvent fromNip01Event(Nip01Event event) {
    return DbEvent(
      id: event.id,
      pubKey: event.pubKey,
      kind: event.kind,
      tagsJson: jsonEncode(event.tags),
      content: event.content,
      createdAt: event.createdAt,
      sig: event.sig,
      validSig: event.validSig,
      sources: event.sources,
    );
  }
}
