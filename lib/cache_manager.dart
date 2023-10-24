import 'package:dart_ndk/db/relay_set.dart';
import 'package:dart_ndk/db/user_contacts.dart';
import 'package:dart_ndk/db/user_relay_list.dart';

abstract class CacheManager {

  Future<void> saveUserRelayList(UserRelayList userRelayList);
  Future<void> saveUserRelayLists(List<UserRelayList> userRelayLists);
  UserRelayList? loadUserRelayList(String pubKey);

  RelaySet? loadRelaySet(String name, String pubKey);
  Future<void> saveRelaySet(RelaySet relaySet);

  Future<void> saveUserContacts(UserContacts userContacts);
  Future<void> saveManyUserContacts(List<UserContacts> userContacts);
  UserContacts? loadUserContacts(String pubKey);
}
