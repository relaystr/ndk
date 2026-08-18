/// What a relay did with a request.
///
/// Declared in collapse precedence order: one request can run on several
/// connections to the same relay, an anonymous one handed over to an
/// authenticated one, and the url reports the first of these its connections
/// reached.
enum RelayRequestOutcomeType {
  /// the relay has not ended the request, it may still send events
  pending,

  /// the relay sent an EOSE, it has given everything it stored
  eose,

  /// the relay ended the request itself with a CLOSED
  closed,

  /// the connection went away before the relay ended the request
  disconnected,

  /// the request ran into its timeout before the relay ended it
  timedOut,

  /// the request never reached the relay
  notSent,
}

/// What a request ended with on a single relay
class RelayRequestOutcome {
  /// what the relay did with the request
  final RelayRequestOutcomeType type;

  /// why, when there is a reason to give: the message of a CLOSED, or what
  /// kept the request from being sent
  final String? message;

  /// creates a new [RelayRequestOutcome]
  const RelayRequestOutcome(this.type, {this.message});

  @override
  String toString() => message == null ? type.name : '${type.name}: $message';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RelayRequestOutcome &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          message == other.message;

  @override
  int get hashCode => Object.hash(type, message);
}
