import 'nip_01_event.dart';
import 'signer_request_cancelled_exception.dart';

/// Signs the kind 24242 event an operation authorises itself with.
typedef BlossomAuthorizationSigner = Future<Nip01Event> Function();

/// What a blossom operation does about the `Authorization` header, and when.
///
/// One operation may talk to several servers. The three cases differ only in
/// *when* the kind 24242 event is signed, never in what it says: the event is
/// not bound to a server, so one signature covers every server the operation
/// reaches. Under [BlossomAuthorization.onRefusal] it still goes only to the
/// servers that refused a request without it.
///
/// This is the repository-facing half of [AuthPolicy]: the usecase decides
/// which identity may be revealed, this decides when the header goes out.
sealed class BlossomAuthorization {
  const BlossomAuthorization();

  /// Sends no `Authorization` header, ever. A server that refuses the request
  /// without one simply does not serve it.
  const factory BlossomAuthorization.none() = BlossomAuthorizationNone;

  /// Sends [event] from the very first request.
  const factory BlossomAuthorization.upfront(Nip01Event event) =
      BlossomAuthorizationUpfront;

  /// Sends nothing at first, and signs with [sign] only once a server refused
  /// the request without an identity.
  factory BlossomAuthorization.onRefusal(BlossomAuthorizationSigner sign) =
      BlossomAuthorizationOnRefusal;

  /// The event to send before anything has been refused, null when the first
  /// request goes out bare.
  Nip01Event? get upfront;

  /// The event a request [serverUrl] refused may be replayed with, null when a
  /// refusal is final. Signs on the first call and returns that same signature
  /// to every later caller, so one operation signs once however many servers
  /// refuse. That matters for remote signers, where each signature is a prompt
  /// in front of the user.
  ///
  /// A signature the user cancelled is remembered too, so the remaining
  /// servers do not prompt again for something already declined. A signature
  /// that failed for any other reason is not: the next server asks again.
  Future<Nip01Event?> onRefusal(String serverUrl);

  /// The event a refusal from [serverUrl] already produced, null while that
  /// server has not refused. Lets the rest of the operation send it to that
  /// server from the start rather than pay a refusal each time, without
  /// showing it to a server that never asked.
  Nip01Event? resolvedFor(String serverUrl);
}

/// Never authorises, see [BlossomAuthorization.none].
class BlossomAuthorizationNone extends BlossomAuthorization {
  /// never authorises
  const BlossomAuthorizationNone();

  @override
  Nip01Event? get upfront => null;

  @override
  Future<Nip01Event?> onRefusal(String serverUrl) async => null;

  @override
  Nip01Event? resolvedFor(String serverUrl) => null;

  @override
  String toString() => 'BlossomAuthorization.none';
}

/// Authorises from the first request, see [BlossomAuthorization.upfront].
class BlossomAuthorizationUpfront extends BlossomAuthorization {
  /// the signed kind 24242 event
  final Nip01Event event;

  /// authorises with [event] from the first request
  const BlossomAuthorizationUpfront(this.event);

  @override
  Nip01Event? get upfront => event;

  @override
  Future<Nip01Event?> onRefusal(String serverUrl) async => event;

  @override
  Nip01Event? resolvedFor(String serverUrl) => event;

  @override
  String toString() => 'BlossomAuthorization.upfront(${event.id})';
}

/// Authorises once refused, see [BlossomAuthorization.onRefusal].
class BlossomAuthorizationOnRefusal extends BlossomAuthorization {
  final BlossomAuthorizationSigner _sign;

  /// assigned synchronously on the first call, so concurrent refusals from
  /// several servers share the one signature
  Future<Nip01Event>? _signed;

  Nip01Event? _resolved;

  final Set<String> _refusedBy = {};

  /// signs with [sign] the first time a server refuses
  BlossomAuthorizationOnRefusal(BlossomAuthorizationSigner sign) : _sign = sign;

  @override
  Nip01Event? get upfront => null;

  @override
  Future<Nip01Event?> onRefusal(String serverUrl) {
    _refusedBy.add(serverUrl);

    final pending = _signed;
    if (pending != null) return pending;

    final attempt = _sign().then((event) => _resolved = event);
    return _signed = attempt.catchError((Object error) {
      // Cancelling a pending request is the one failure that is a decision
      // rather than an incident: nothing but the user reaches it. Every other
      // error, including a bunker answering with one, says nothing about
      // whether they would agree, so the next server asks again.
      if (error is! SignerRequestCancelledException) {
        _signed = null;
      }
      throw error;
    });
  }

  @override
  Nip01Event? resolvedFor(String serverUrl) =>
      _refusedBy.contains(serverUrl) ? _resolved : null;

  @override
  String toString() => 'BlossomAuthorization.onRefusal';
}
