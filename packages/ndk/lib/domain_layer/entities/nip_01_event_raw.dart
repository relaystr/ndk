import 'package:ndk/ndk.dart';

enum NostrMessageRawType {
  notice,
  event,
  eose,
  ok,
  closed,
  auth,
  unknown,
}

class NostrMessageRaw {
  final NostrMessageRawType type;
  final Nip01Event? nip01Event;
  final String? requestId;
  final dynamic otherData;

  NostrMessageRaw({
    required this.type,
    this.nip01Event,
    this.requestId,
    this.otherData,
  });
}
