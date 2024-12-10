import 'package:collection/collection.dart';

import 'nip_01_event.dart';

/// relay stats
class RelayStats {
  /// number of connections
  int connections = 0;

  /// number of connection errors
  int connectionErrors = 0;

  /// number of active requests on this relay
  int activeRequests = 0;

  /// gets incremented on every touch => search if it has a pubkey assigned
  int touched = 1;

  /// gets incremented when there is a pubkey match
  int touchUseful = 0;

  /// describes how often the relay was used and returned something useful
  double get relayUsefulness => touchUseful / touched;

  /// kind as keys, count as values
  Map<int, int> eventsRead = {};

  /// kind as keys, count as values
  Map<int, int> eventsWritten = {};

  /// kind as keys, bytes amount as values
  Map<int, int> dataReadBytes = {};

  /// kind as keys, bytes amount as values
  Map<int, int> dataWrittenBytes = {};

  /// Get total number of read events in this relay
  int getTotalEventsRead() {
    return eventsRead.values.sum;
  }

  /// Get total bytes read this relay
  int getTotalBytesRead() {
    return dataReadBytes.values.sum;
  }

  /// increment stats by new event
  void incStatsByNewEvent(Nip01Event event, int bytes) {
    int eventsRead = this.eventsRead[event.kind] ?? 0;
    this.eventsRead[event.kind] = eventsRead + 1;
    int bytesRead = this.dataReadBytes[event.kind] ?? 0;
    this.dataReadBytes[event.kind] = bytesRead + bytes;
  }
}
