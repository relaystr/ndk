import '../repositories/event_signer.dart';
import 'pending_signer_request.dart';

enum AccountType { privateKey, publicKey, externalSigner }

/// Account entity
class Account {
  final AccountType type;
  final String pubkey;
  final EventSigner signer;

  Account({required this.type, required this.pubkey, required this.signer});

  /// Stream of pending signer requests waiting for user approval.
  ///
  /// For accounts using local signers (private key), this will always emit
  /// an empty list. For accounts using remote signers (NIP-46 bunkers, etc.),
  /// this will emit requests waiting for user approval.
  Stream<List<PendingSignerRequest>> get pendingRequestsStream =>
      signer.pendingRequestsStream;

  /// Current list of pending signer requests (synchronous snapshot).
  List<PendingSignerRequest> get pendingRequests => signer.pendingRequests;

  /// Cancel a pending request by its ID.
  ///
  /// Returns true if the request was found and cancelled.
  bool cancelRequest(String requestId) => signer.cancelRequest(requestId);

  /// Dispose of resources used by the signer.
  ///
  /// Call this when the account is no longer needed to avoid memory leaks.
  Future<void> dispose() => signer.dispose();
}
