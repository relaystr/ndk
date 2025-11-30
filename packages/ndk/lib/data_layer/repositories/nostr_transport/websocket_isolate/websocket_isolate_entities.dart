part of 'websocket_isolate_nostr_transport.dart';

/// Message types for isolate communication
enum _IsolateMessageType {
  ready,
  reconnecting,
  message,
  error,
  done,
}

/// Internal message class for communication between main isolate and worker isolate
class _IsolateMessage {
  /// connection id is the cleaned relay url, (needed so reconnect, restore state works)
  final String connectionId;
  final _IsolateMessageType type;
  final NostrMessageRaw? data;
  final String? error;
  final int? closeCode;
  final String? closeReason;

  _IsolateMessage({
    required this.connectionId,
    required this.type,
    this.data,
    this.error,
    this.closeCode,
    this.closeReason,
  });
}

/// Base class for commands sent from main isolate to worker isolate
abstract class _IsolateCommand {
  final String connectionId;

  _IsolateCommand({required this.connectionId});
}

class _ConnectCommand extends _IsolateCommand {
  final String url;

  _ConnectCommand({required super.connectionId, required this.url});
}

class _SendCommand extends _IsolateCommand {
  final dynamic data;

  _SendCommand({required super.connectionId, required this.data});
}

class _CloseCommand extends _IsolateCommand {
  _CloseCommand({required super.connectionId});
}

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
