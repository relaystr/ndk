import 'nip_17_message.dart';

class Nip17Conversation {
  final String peerPubKey;
  final List<Nip17Message> messages;

  const Nip17Conversation({
    required this.peerPubKey,
    required this.messages,
  });

  Nip17Message get latestMessage => messages.last;
  int get latestCreatedAt => latestMessage.createdAt;
}
