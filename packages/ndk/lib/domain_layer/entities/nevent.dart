/// Represents a decoded nevent (event reference)
class Nevent {
  final String eventId;
  final String? author;
  final int? kind;
  final List<String>? relays;

  Nevent({
    required this.eventId,
    this.author,
    this.kind,
    this.relays,
  });

  @override
  String toString() =>
      'Nevent(eventId: $eventId, author: $author, kind: $kind, relays: $relays)';
}
