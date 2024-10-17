import 'dart:developer';

import 'package:logger/logger.dart';

import '../../../config/bootstrap_relays.dart';
import '../../entities/nip_01_event.dart';
import '../../entities/nip_65.dart';
import '../../entities/read_write_marker.dart';
import '../../repositories/cache_manager.dart';

/// reads the latest nip65 data from cache
/// [pubkeys] pubkeys you want nip65 data for
/// [cacheManger] the cache manager you want to use
List<Nip65> getNip65Data(List<String> pubkeys, CacheManager cacheManager) {
  List<Nip01Event> events =
      cacheManager.loadEvents(kinds: [Nip65.KIND], pubKeys: pubkeys);

  List<Nip65> nip65Data = [];
  for (var event in events) {
    nip65Data.add(Nip65.fromEvent(event));
  }
  return nip65Data;
}

/// reads the latest nip65 data from cache
/// [pubkey] pubkey you want nip65 data for
/// [cacheManger] the cache manager you want to use
Nip65 getNip65DataSingle(String pubkey, CacheManager cacheManager) {
  final data = getNip65Data([pubkey], cacheManager);

  // default
  if (data.isEmpty) {
    log(
      "WARN: using default bootstrap relays as nip65 data!",
      level: Level.warning.value,
    );
    // list to map
    Map<String, ReadWriteMarker> newReadWrite = {};
    for (var relay in DEFAULT_BOOTSTRAP_RELAYS) {
      newReadWrite[relay] = ReadWriteMarker.readWrite;
    }

    return Nip65.fromMap(pubkey, newReadWrite);
  }
  return data[0];
}
