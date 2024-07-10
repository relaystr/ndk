import 'dart:async';

import 'package:dart_ndk/data_layer/data_sources/websocket.dart';

import '../../domain_layer/repositories/nostr_transport_repository.dart';

class NostrTransportRepositoryImpl implements NostrTransportRepository {
  WebsocketDS websocketDS;

  NostrTransportRepositoryImpl(this.websocketDS) {
    ready = websocketDS.ready();
  }

  @override
  late Future<void> ready;

  @override
  Future<void> close() {
    return websocketDS.close();
  }

  @override
  StreamSubscription listen(void Function(dynamic p1) onData,
      {Function? onError, void Function()? onDone}) {
    return websocketDS.listen(onData, onError: onError, onDone: onDone);
  }

  @override
  void send(data) {
    websocketDS.send(data);
  }
}
