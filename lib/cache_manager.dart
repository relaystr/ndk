import 'package:dart_ndk/db/relay_set.dart';
import 'package:dart_ndk/db/user_contacts.dart';
import 'package:dart_ndk/db/user_metadata.dart';
import 'package:dart_ndk/db/user_relay_list.dart';

abstract class CacheManager {

  Future<void> saveUserRelayList(UserRelayList userRelayList);
  Future<void> saveUserRelayLists(List<UserRelayList> userRelayLists);
  UserRelayList? loadUserRelayList(String pubKey);
  Future<void> removeUserRelayList(String pubKey);
  Future<void> removeAllUserRelayLists();

  RelaySet? loadRelaySet(String name, String pubKey);
  Future<void> saveRelaySet(RelaySet relaySet);
  Future<void> removeRelaySet(String name, String pubKey);
  Future<void> removeAllRelaySets();

  Future<void> saveUserContacts(UserContacts userContacts);
  Future<void> saveManyUserContacts(List<UserContacts> userContacts);
  UserContacts? loadUserContacts(String pubKey);
  Future<void> removeUserContacts(String pubKey);
  Future<void> removeAllUserContacts();

  Future<void> saveUserMetadata(UserMetadata metadata);
  Future<void> saveUserMetadatas(List<UserMetadata> metadatas);
  UserMetadata? loadUserMetadata(String pubKey);
  List<UserMetadata?> loadUserMetadatas(List<String> pubKeys);
  Future<void> removeUserMetadata(String pubKey);
  Future<void> removeAllUserMetadatas();

}
