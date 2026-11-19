import 'package:ndk_core/domain_layer/entities/relay_set.dart';

abstract interface class RelaySetStore {
  Future<RelaySet?> loadRelaySet(String name, String pubKey);
  Future<void> saveRelaySet(RelaySet relaySet);
  Future<void> removeRelaySet(String name, String pubKey);
  Future<void> removeAllRelaySets();
}
