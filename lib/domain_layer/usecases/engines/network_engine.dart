import '../../entities/nip_01_event.dart';
import '../../entities/request_state.dart';

abstract class NetworkEngine {
  void handleRequest(RequestState requestState);

  // todo:
  // response obj?
  // implement in both engines
  // Future<void> handleEventPublish(Nip01Event nostrEvent);

  // todo:
  // response obj?
  // implement in both engines
  // Future<void> handleCloseSubscription(String subId);
}
