import 'dart:async';

abstract class NostrTransport {
  late Future<void> ready;
  bool isOpen();
  bool isConnecting();
  Future<void> close();
  void send(dynamic data);
  StreamSubscription listen(
    void Function(dynamic) onData, {
    Function? onError,
    void Function()? onDone,
  });

  int? closeCode();
  String? closeReason();
}

abstract class NostrTransportFactory {
  NostrTransport call(String url,
      {Function? onReconnect, Function(int?, Object?, String?)? onDisconnect});
}
