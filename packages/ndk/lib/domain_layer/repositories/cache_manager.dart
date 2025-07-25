import '../entities/cashu/wallet_cahsu_keyset.dart';
import '../entities/cashu/wallet_cashu_proof.dart';
import '../entities/contact_list.dart';
import '../entities/nip_01_event.dart';
import '../entities/nip_05.dart';
import '../entities/relay_set.dart';
import '../entities/user_relay_list.dart';
import '../entities/metadata.dart';

abstract class CacheManager {
  /// closes the cache manger \
  /// used to close the db
  Future<void> close();

  Future<void> saveEvent(Nip01Event event);
  Future<void> saveEvents(List<Nip01Event> events);
  Future<Nip01Event?> loadEvent(String id);
  Future<List<Nip01Event>> loadEvents({
    List<String> pubKeys,
    List<int> kinds,
    String? pTag,
    int? since,
    int? until,
  });
  Future<void> removeEvent(String id);
  Future<void> removeAllEventsByPubKey(String pubKey);
  Future<void> removeAllEvents();

  Future<void> saveUserRelayList(UserRelayList userRelayList);
  Future<void> saveUserRelayLists(List<UserRelayList> userRelayLists);
  Future<UserRelayList?> loadUserRelayList(String pubKey);
  Future<void> removeUserRelayList(String pubKey);
  Future<void> removeAllUserRelayLists();

  Future<RelaySet?> loadRelaySet(String name, String pubKey);
  Future<void> saveRelaySet(RelaySet relaySet);
  Future<void> removeRelaySet(String name, String pubKey);
  Future<void> removeAllRelaySets();

  Future<void> saveContactList(ContactList contactList);
  Future<void> saveContactLists(List<ContactList> contactLists);
  Future<ContactList?> loadContactList(String pubKey);
  Future<void> removeContactList(String pubKey);
  Future<void> removeAllContactLists();

  Future<void> saveMetadata(Metadata metadata);
  Future<void> saveMetadatas(List<Metadata> metadatas);
  Future<Metadata?> loadMetadata(String pubKey);
  Future<List<Metadata?>> loadMetadatas(List<String> pubKeys);
  Future<void> removeMetadata(String pubKey);
  Future<void> removeAllMetadatas();

  /// Search by name, nip05
  Future<Iterable<Metadata>> searchMetadatas(String search, int limit);

  /// search events \
  /// [ids] - list of event ids \
  /// [authors] - list of authors pubKeys \
  /// [kinds] - list of kinds \
  /// [tags] - map of tags \
  /// [since] - timestamp \
  /// [until] - timestamp \
  /// [search] - search string to match against content \
  /// [limit] - limit of results \
  /// returns list of events
  Future<Iterable<Nip01Event>> searchEvents({
    List<String>? ids,
    List<String>? authors,
    List<int>? kinds,
    Map<String, List<String>>? tags,
    int? since,
    int? until,
    String? search,
    int limit = 100,
  });

  Future<void> saveNip05(Nip05 nip05);
  Future<void> saveNip05s(List<Nip05> nip05s);
  Future<Nip05?> loadNip05(String pubKey);
  Future<List<Nip05?>> loadNip05s(List<String> pubKeys);
  Future<void> removeNip05(String pubKey);
  Future<void> removeAllNip05s();

  /// cashu methods

  Future<void> saveKeyset(WalletCahsuKeyset keyset);
  Future<List<WalletCahsuKeyset>> getKeysets({
    required String mintURL,
  });

  Future<void> saveProofs({
    required List<WalletCashuProof> tokens,
    required String mintUrl,
  });

  Future<List<WalletCashuProof>> getProofs({
    required String mintUrl,
    String? keysetId,
  });

  Future<void> removeProof({
    required WalletCashuProof proof,
    required String mintUrl,
  });
}
