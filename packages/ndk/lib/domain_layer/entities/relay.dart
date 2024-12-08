import 'connection_source.dart';

class Relay {
  /// relay url
  String url;

  /// is it connecting
  bool connecting = false;

  /// last connection try timestamp
  int? lastConnectTry;

  /// last successful connection
  int? lastSuccessfulConnect;

  ConnectionSource connectionSource;

  Relay({
    required this.url,
    required this.connectionSource,
  });

  /// set trying to connect
  void tryingToConnect() {
    lastConnectTry = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    connecting = true;
  }

  /// mark as succeded to connect
  void succeededToConnect() {
    lastSuccessfulConnect = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    connecting = false;
  }

  /// mark as failed to connect
  void failedToConnect() {
    connecting = false;
  }

  /// was last connection try longer than given seconds
  bool wasLastConnectTryLongerThanSeconds(int seconds) {
    return lastConnectTry == null ||
        lastConnectTry! <
            DateTime.now()
                    .add(Duration(seconds: -seconds))
                    .millisecondsSinceEpoch ~/
                1000;
  }
}
