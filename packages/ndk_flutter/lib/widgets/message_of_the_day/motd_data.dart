import 'package:ndk/ndk.dart';

/// Holds the parsed content of a Message of the Day (NIP-78 kind 30078) event.
class MotdData {
  /// Event kind used for Message of the Day events.
  static const int kKind = 30078;

  /// Default `d` tag value identifying a Message of the Day event.
  static const String kDefaultDTag = 'motd';

  /// URI schemes accepted for the event-provided `url` tag by default.
  ///
  /// Only `https` is safe to open blindly: any other scheme can address a
  /// native handler (deep links, `intent://` on Android, ...) and would let a
  /// hostile publisher hijack the popup's link button.
  static const Set<String> kDefaultLinkSchemes = {'https'};

  /// The resolved event id (nips-01 id of the underlying event).
  final String eventId;

  /// Public key of the event author.
  final String pubKey;

  /// Message content displayed to the user.
  final String message;

  /// Optional link shown as a second button in the popup.
  final String? url;

  /// Optional title displayed in the popup header.
  ///
  /// When absent (or empty), the widget falls back to the localized default
  /// "Message of the Day" title.
  final String? title;

  /// Optional minimum app version this message applies to.
  ///
  /// When both this value and the supplied app version are present, the popup
  /// is hidden only when the app version is older than this version.
  final String? version;

  /// Unix timestamp of the event.
  final int createdAt;

  const MotdData({
    required this.eventId,
    required this.pubKey,
    required this.message,
    this.url,
    this.title,
    this.version,
    required this.createdAt,
  });

  /// Parses the `url` tag value into a [Uri] that is safe to hand to an
  /// external launcher, or null when it must not be opened.
  static Uri? resolveLinkUrl(
    String? url, {
    Set<String> allowedSchemes = kDefaultLinkSchemes,
  }) {
    final raw = url?.trim();
    if (raw == null || raw.isEmpty) return null;

    final parsed = Uri.tryParse(raw);
    if (parsed == null) return null;

    final scheme = parsed.scheme.toLowerCase();
    if (scheme.isEmpty) return null;
    final allowed = allowedSchemes.map((s) => s.toLowerCase()).toSet();
    if (!allowed.contains(scheme)) return null;
    if (parsed.hasAuthority && parsed.host.isEmpty) return null;

    return parsed;
  }

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
      title: event.getFirstTag('title'),
      version: event.getFirstTag('version'),
      createdAt: event.createdAt,
    );
  }
}
