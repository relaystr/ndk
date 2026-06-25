import 'nip_01_event.dart';

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

  String get id => rumor.id;
  String get content => rumor.content;
  int get createdAt => rumor.createdAt;
}
