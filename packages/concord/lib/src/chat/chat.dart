import 'package:ndk/domain_layer/entities/nip_01_event.dart';

import '../core/concord_constants.dart';
import '../core/concord_time.dart';
import '../core/encoding.dart';

/// A Chat Plane rumor (CORD-02 §5, Appendix B). The binding tags
/// `["channel", …]` and `["epoch", …]` are checked against the coordinate
/// whose key opened the wrap (CORD-01 "Binding").
class ChatMessage {
  final String id;
  final String author;
  final int kind;
  final String content;
  final List<List<String>> tags;
  final int createdAt;
  final int ms;

  /// True time basis: `created_at * 1000 + ms`.
  final int at;

  const ChatMessage({
    required this.id,
    required this.author,
    required this.kind,
    required this.content,
    required this.tags,
    required this.createdAt,
    required this.ms,
    required this.at,
  });

  String? get channelId => _tag('channel');
  String? get epochTag => _tag('epoch');

  /// The rumor a reply/reaction/edit/delete points at (`e` tag).
  String? get target => _tag('e');

  bool get isMessage =>
      kind == RumorKinds.message || kind == RumorKinds.threadedReply;
  bool get isReaction => kind == RumorKinds.reaction;
  bool get isDelete => kind == RumorKinds.delete;
  bool get isEdit => kind == RumorKinds.edit;
  bool get isTimerNotice => kind == RumorKinds.timerNotice;

  String? _tag(String name) {
    for (final tag in tags) {
      if (tag.length >= 2 && tag[0] == name) return tag[1];
    }
    return null;
  }

  /// Parses a chat rumor. Returns null when the binding tags or the `ms`
  /// tag are malformed (the entry is then dropped, never interpreted).
  static ChatMessage? tryParse(Nip01Event rumor) {
    switch (rumor.kind) {
      case RumorKinds.message:
      case RumorKinds.threadedReply:
      case RumorKinds.reaction:
      case RumorKinds.delete:
      case RumorKinds.edit:
      case RumorKinds.timerNotice:
      case RumorKinds.webxdc:
        break;
      default:
        return null;
    }
    final at = Millis.of(rumor);
    if (at == null) return null;
    return ChatMessage(
      id: rumor.id,
      author: rumor.pubKey,
      kind: rumor.kind,
      content: rumor.content,
      tags: rumor.tags,
      createdAt: rumor.createdAt,
      ms: Millis.msOf(rumor)!,
      at: at,
    );
  }
}

/// One Channel-epoch's Chat fold (CORD-02 §5).
///
/// Bound to a channel id and epoch: a rumor whose binding tags disagree is
/// refused, so a stream key lifted to another context cannot smuggle
/// messages in. Drops banned authors and already-expired rumors at ingest.
class ChatChannelFold {
  final String channelId;
  final int epoch;

  final Map<String, ChatMessage> _byId = {};
  final Set<String> _deleted = {};

  ChatChannelFold({required this.channelId, required this.epoch});

  Iterable<ChatMessage> get all => _byId.values;

  /// Ingests a chat rumor. Returns true when it was accepted.
  bool ingest(
    Nip01Event rumor, {
    required bool Function(String author) isBanned,
    required int nowSeconds,
  }) {
    final message = ChatMessage.tryParse(rumor);
    if (message == null) return false;
    if (message.channelId != channelId) return false;
    if (message.epochTag != decimalTag(epoch)) return false;
    if (isBanned(message.author)) return false;
    // CORD-08 §3: an already-expired rumor is refused at ingest.
    if (Expiration.isExpired(rumor, nowSeconds: nowSeconds)) return false;

    _byId[message.id] = message;
    if (message.isDelete && message.target != null) {
      _deleted.add(message.target!);
    }
    return true;
  }

  /// Removes a message by its rumor id (used when an author deletes their
  /// own event, always honored — CORD-02 §9).
  void dropRumor(String id) => _byId.remove(id);

  /// The surviving messages, oldest first, ordered by true millisecond time
  /// then lower rumor id. Delete and edit targets are resolved through
  /// [editedContent] / [reactions] by the caller.
  List<ChatMessage> messages() {
    final list = _byId.values
        .where(
          (m) => !_deleted.contains(m.id) && (m.isMessage || m.isTimerNotice),
        )
        .toList();
    list.sort(_compare);
    return list;
  }

  /// Editions (kind 3302) that supersede a message's content, keyed by the
  /// target rumor id.
  String? editedContent(String messageId) {
    ChatMessage? latest;
    for (final m in _byId.values) {
      if (!m.isEdit || m.target != messageId) continue;
      if (latest == null || _compare(m, latest) > 0) latest = m;
    }
    return latest?.content;
  }

  /// Reactions to a message: emoji -> count.
  Map<String, int> reactions(String messageId) {
    final out = <String, int>{};
    for (final m in _byId.values) {
      if (!m.isReaction || m.target != messageId) continue;
      if (_deleted.contains(m.id)) continue;
      out.update(m.content, (n) => n + 1, ifAbsent: () => 1);
    }
    return out;
  }

  static int _compare(ChatMessage a, ChatMessage b) {
    final byTime = a.at.compareTo(b.at);
    if (byTime != 0) return byTime;
    return a.id.compareTo(b.id);
  }
}
