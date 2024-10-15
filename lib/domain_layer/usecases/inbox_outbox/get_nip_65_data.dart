import '../../entities/nip_01_event.dart';
import '../../entities/nip_65.dart';
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
  return getNip65Data([pubkey], cacheManager)[0];
}
