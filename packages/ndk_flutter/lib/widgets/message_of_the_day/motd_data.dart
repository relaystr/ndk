import 'package:ndk/ndk.dart';

/// Holds the parsed content of a Message of the Day (NIP-78 kind 30078) event.
class MotdData {
  /// Event kind used for Message of the Day events.
  static const int kKind = 30078;

  /// Default `d` tag value identifying a Message of the Day event.
  static const String kDefaultDTag = 'motd';

  /// The resolved event id (nips-01 id of the underlying event).
  final String eventId;

  /// Public key of the event author.
  final String pubKey;

  /// Message content displayed to the user.
  final String message;

  /// Optional link shown as a second button in the popup.
  final String? url;

  /// Optional version this message applies to.
  ///
  /// When both this value and the supplied app version are present, the popup
  /// is only shown if this version is newer than the app version.
  final String? version;

  /// Unix timestamp of the event.
  final int createdAt;

  const MotdData({
    required this.eventId,
    required this.pubKey,
    required this.message,
    this.url,
    this.version,
    required this.createdAt,
  });

  /// Parses a [MotdData] from a raw [Nip01Event].
  ///
  /// A [Nip01Event] is used as-is; validation (kind, `d` tag, author) is left
  /// to the caller.
  factory MotdData.fromEvent(Nip01Event event) {
    return MotdData(
      eventId: event.id,
      pubKey: event.pubKey,
      message: event.content,
      url: event.getFirstTag('url'),
      version: event.getFirstTag('version'),
      createdAt: event.createdAt,
    );
  }
}