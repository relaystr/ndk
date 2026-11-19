import '../../entities/user_relay_list.dart';

abstract interface class UserRelayListStore {
  /// Store a precomputed user relay list projection.
  ///
  /// This remains a convenience projection. The authoritative data still comes
  /// from the generic event store (for example kind `3` and kind `10002`
  /// inputs).
  Future<void> saveUserRelayList(UserRelayList userRelayList);
  Future<void> saveUserRelayLists(List<UserRelayList> userRelayLists);
  Future<UserRelayList?> loadUserRelayList(String pubKey);
  Future<void> removeUserRelayList(String pubKey);
  Future<void> removeAllUserRelayLists();
}
