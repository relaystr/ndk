import '../../entities/broadcast_response.dart';
import '../../entities/broadcast_state.dart';
import '../../entities/nip_01_event.dart';
import '../../entities/request_state.dart';
import '../../repositories/event_signer.dart';

abstract class NetworkEngine {
  void handleRequest(RequestState requestState);

  NdkBroadcastResponse handleEventBroadcast({
    required Nip01Event nostrEvent,
    required EventSigner mySigner,
    required Stream<List<RelayBroadcastResponse>> doneStream,
    Iterable<String>? specificRelays,
  });

  /// closes the nostr network subscription
  Future<void> closeSubscription(String subId);
}
