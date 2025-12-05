enum NostrMessageRawType {
  notice,
  event,
  eose,
  ok,
  closed,
  auth,
  unknown,
}

//? needed until Nip01Event is refactored to be immutable
class Nip01EventRaw {
  final String id;

  final String pubKey;

  final int createdAt;

  final int kind;

  final List<List<String>> tags;

  final String content;

  final String sig;

  Nip01EventRaw({
    required this.id,
    required this.pubKey,
    required this.createdAt,
    required this.kind,
    required this.tags,
    required this.content,
    required this.sig,
  });
}

class NostrMessageRaw {
  final NostrMessageRawType type;
  final Nip01EventRaw? nip01Event;
  final String? requestId;
  final dynamic otherData;

  NostrMessageRaw({
    required this.type,
    this.nip01Event,
    this.requestId,
    this.otherData,
  });
}
