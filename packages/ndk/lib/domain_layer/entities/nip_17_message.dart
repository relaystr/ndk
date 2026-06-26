import 'nip_01_event.dart';

/// Parsed direct-message item produced by the NIP-17 DM usecase.
///
/// [wrappedEvent] is the original gift-wrapped event stored and transported on
/// relays.
///
/// [rumor] is the decrypted inner message event.
///
/// [peerPubKey] is the other participant in the conversation relative to the
/// logged-in user.
class Nip17Message {
  final Nip01Event wrappedEvent;
  final Nip01Event rumor;
  final String peerPubKey;
  final bool isOutgoing;

  const Nip17Message({
    required this.wrappedEvent,
    required this.rumor,
    required this.peerPubKey,
    required this.isOutgoing,
  });

  /// Stable message id derived from the decrypted rumor event.
  String get id => rumor.id;

  /// Decrypted message content.
  String get content => rumor.content;

  /// Message creation timestamp from the decrypted rumor event.
  int get createdAt => rumor.createdAt;
}
