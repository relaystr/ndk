import '../../entities/broadcast_response.dart';
import '../../entities/nip_01_event.dart';
import '../../entities/request_state.dart';

abstract class NetworkEngine {
  void handleRequest(RequestState requestState);

  NdkBroadcastResponse handleEventBroadcast({
    required Nip01Event nostrEvent,
    required String privateKey,
    List<String>? specificRelays,
  });

  // todo:
  // response obj?
  // implement in both engines
  // Future<void> handleCloseSubscription(String subId);
}
