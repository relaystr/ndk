import 'nip_17_message.dart';

/// Group of NIP-17 messages exchanged with one peer.
///
/// Messages are expected to be sorted in ascending creation order inside the
/// conversation.
class Nip17Conversation {
  final String peerPubKey;
  final List<Nip17Message> messages;

  const Nip17Conversation({
    required this.peerPubKey,
    required this.messages,
  });

  /// Most recent message in the conversation.
  Nip17Message get latestMessage => messages.last;

  /// Creation timestamp of the most recent message.
  int get latestCreatedAt => latestMessage.createdAt;
}
