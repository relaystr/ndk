import 'connection_source.dart';
import 'nip_01_event.dart';
import 'relay_info.dart';
import 'relay_stats.dart';

class Relay {
  /// relay url
  String url;

  /// is it connecting
  bool connecting = false;

  /// last connection try timestamp
  int? lastConnectTry;

  /// last successful connection
  int? lastSuccessfulConnect;

  /// relay info
  RelayInfo? info;

  /// relay stats
  RelayStats stats = RelayStats();

  ConnectionSource connectionSource;

  Relay({
    required this.url,
    required this.connectionSource,
  });

  /// does this relay support given nip
  bool supportsNip(int nip) {
    return info != null && info!.nips.contains(nip);
  }

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

  /// increment stats by new event
  void incStatsByNewEvent(Nip01Event event, int bytes) {
    int eventsRead = stats.eventsRead[event.kind] ?? 0;
    stats.eventsRead[event.kind] = eventsRead + 1;
    int bytesRead = stats.dataReadBytes[event.kind] ?? 0;
    stats.dataReadBytes[event.kind] = bytesRead + bytes;
  }
}
