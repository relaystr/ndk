import 'dart:core';

import '../../../domain_layer/entities/cashu/cashu_keyset.dart';
import '../../../domain_layer/entities/cashu/cashu_mint_info.dart';
import '../../../domain_layer/entities/cashu/cashu_proof.dart';
import '../../../domain_layer/entities/contact_list.dart';
import '../../../domain_layer/entities/nip_01_event.dart';
import '../../../domain_layer/entities/nip_05.dart';
import '../../../domain_layer/entities/relay_set.dart';
import '../../../domain_layer/entities/user_relay_list.dart';
import '../../../domain_layer/entities/metadata.dart';
import '../../../domain_layer/entities/wallet/wallet.dart';
import '../../../domain_layer/entities/wallet/wallet_transaction.dart';
import '../../../domain_layer/entities/wallet/wallet_type.dart';
import '../../../domain_layer/repositories/cache_manager.dart';

/// In memory database implementation
/// benefits: very fast
/// drawbacks: does not persist
class MemCacheManager implements CacheManager {
  /// In memory storage
  Map<String, UserRelayList> userRelayLists = {};

  /// In memory storage
  Map<String, RelaySet> relaySets = {};

  /// In memory storage
  Map<String, ContactList> contactLists = {};

  /// In memory storage
  Map<String, Metadata> metadatas = {};

  /// In memory storage
  Map<String, Nip05> nip05s = {};

  /// In memory storage
  Map<String, Nip01Event> events = {};

  /// String for mint Url
  Map<String, Set<CahsuKeyset>> cashuKeysets = {};

  /// String for mint Url
  Map<String, Set<CashuProof>> cashuProofs = {};

  List<WalletTransaction> transactions = [];

  Set<Wallet> wallets = {};

  Set<CashuMintInfo> cashuMintInfos = {};

  /// In memory storage for cashu secret counters
  /// Key is a combination of mintUrl and keysetId
  /// value is the counter
  final Map<String, int> _cashuSecretCounters = {};

  @override
  Future<void> saveUserRelayList(UserRelayList userRelayList) async {
    userRelayLists[userRelayList.pubKey] = userRelayList;
  }

  @override
  Future<UserRelayList?> loadUserRelayList(String pubKey) async {
    return userRelayLists[pubKey];
  }

  @override
  Future<void> saveUserRelayLists(List<UserRelayList> userRelayLists) async {
    for (var userRelayList in userRelayLists) {
      this.userRelayLists[userRelayList.pubKey] = userRelayList;
    }
  }

  @override
  Future<void> removeAllUserRelayLists() async {
    userRelayLists.clear();
  }

  @override
  Future<void> removeUserRelayList(String pubKey) async {
    userRelayLists.remove(pubKey);
  }

  /// **************************************************************************

  @override
  Future<void> saveNip05(Nip05 nip05) async {
    nip05s[nip05.pubKey] = nip05;
  }

  @override
  Future<Nip05?> loadNip05(String pubKey) async {
    return nip05s[pubKey];
  }

  @override
  Future<List<Nip05?>> loadNip05s(List<String> pubKeys) async {
    List<Nip05> result = [];
    for (String pubKey in pubKeys) {
      Nip05? nip05 = nip05s[pubKey];
      if (nip05 != null) {
        result.add(nip05);
      }
    }
    return result;
  }

  @override
  Future<void> saveNip05s(List<Nip05> nip05s) async {
    for (var nip05 in nip05s) {
      this.nip05s[nip05.pubKey] = nip05;
    }
  }

  @override
  Future<void> removeAllNip05s() async {
    nip05s.clear();
  }

  @override
  Future<void> removeNip05(String pubKey) async {
    nip05s.remove(pubKey);
  }

  /// **************************************************************************

  @override
  Future<RelaySet?> loadRelaySet(String name, String pubKey) async {
    return relaySets[RelaySet.buildId(name, pubKey)];
  }

  @override
  Future<void> saveRelaySet(RelaySet relaySet) async {
    relaySets[relaySet.id] = relaySet;
  }

  @override
  Future<ContactList?> loadContactList(String pubKey) async {
    return contactLists[pubKey];
  }

  @override
  Future<void> saveContactList(ContactList contactList) async {
    contactLists[contactList.pubKey] = contactList;
  }

  @override
  Future<void> saveContactLists(List<ContactList> list) async {
    for (var contactList in list) {
      contactLists[contactList.pubKey] = contactList;
    }
  }

  @override
  Future<Metadata?> loadMetadata(String pubKey) async {
    return metadatas[pubKey];
  }

  @override
  Future<void> saveMetadata(Metadata metadata) async {
    metadatas[metadata.pubKey] = metadata;
  }

  @override
  Future<void> saveMetadatas(List<Metadata> list) async {
    for (var metadata in list) {
      metadatas[metadata.pubKey] = metadata;
    }
  }

  @override
  Future<void> removeAllRelaySets() async {
    relaySets.clear();
  }

  @override
  Future<void> removeAllContactLists() async {
    contactLists.clear();
  }

  @override
  Future<void> removeAllMetadatas() async {
    metadatas.clear();
  }

  @override
  Future<void> removeRelaySet(String name, String pubKey) async {
    relaySets.remove(RelaySet.buildId(name, pubKey));
  }

  @override
  Future<void> removeContactList(String pubKey) async {
    contactLists.remove(pubKey);
  }

  @override
  Future<void> removeMetadata(String pubKey) async {
    metadatas.remove(pubKey);
  }

  @override
  Future<List<Metadata?>> loadMetadatas(List<String> pubKeys) async {
    List<Metadata> result = [];
    for (String pubKey in pubKeys) {
      Metadata? metadata = metadatas[pubKey];
      if (metadata != null) {
        result.add(metadata);
      }
    }
    return result;
  }

  /// Search for metadata by name, nip05
  @override
  Future<Iterable<Metadata>> searchMetadatas(String search, int limit) async {
    // Use a Set to track unique Metadata objects
    final Set<Metadata> uniqueResults = {};

    for (final metadata in metadatas.values) {
      if ((metadata.name != null && metadata.name!.contains(search)) ||
          (metadata.nip05 != null && metadata.nip05!.contains(search))) {
        uniqueResults.add(metadata);
      }
    }

    // Convert to list, sort by updatedAt, and take the limit
    final sortedResults = uniqueResults.toList()
      ..sort((a, b) => (b.updatedAt ?? 0).compareTo(a.updatedAt ?? 0));

    return sortedResults.take(limit);
  }

  @override
  Future<Iterable<Nip01Event>> searchEvents({
    List<String>? ids,
    List<String>? authors,
    List<int>? kinds,
    Map<String, List<String>>? tags,
    int? since,
    int? until,
    String? search,
    int limit = 100,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Nip01Event?> loadEvent(String id) async {
    return events[id];
  }

  @override
  Future<List<Nip01Event>> loadEvents({
    List<String>? pubKeys,
    List<int>? kinds,
    String? pTag,
    int? since,
    int? until,
    int? limit,
  }) async {
    List<Nip01Event> result = [];
    for (var event in events.values) {
      if (pubKeys != null && !pubKeys.contains(event.pubKey)) {
        continue;
      }
      if (kinds != null && !kinds.contains(event.kind)) {
        continue;
      }
      if (pTag != null && !event.pTags.contains(pTag)) {
        continue;
      }

      if (since != null && event.createdAt < since) {
        continue;
      }

      if (until != null && event.createdAt > until) {
        continue;
      }

      result.add(event);
    }

    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (limit != null && limit > 0 && result.length > limit) {
      result = result.take(limit).toList();
    }

    return result;
  }

  @override
  Future<void> removeAllEventsByPubKey(String pubKey) async {
    events.removeWhere((key, value) => value.pubKey == pubKey);
  }

  @override
  Future<void> removeAllEvents() async {
    events.clear();
  }

  @override
  Future<void> removeEvent(String id) async {
    events.remove(id);
  }

  @override
  Future<void> saveEvent(Nip01Event event) async {
    events[event.id] = event;
  }

  @override
  Future<void> saveEvents(List<Nip01Event> events) async {
    for (var event in events) {
      this.events[event.id] = event;
    }
  }

  @override
  Future<void> close() async {
    return;
  }

  @override
  Future<List<CahsuKeyset>> getKeysets({String? mintUrl}) {
    if (cashuKeysets.containsKey(mintUrl)) {
      return Future.value(cashuKeysets[mintUrl]?.toList() ?? []);
    } else {
      return Future.value(cashuKeysets.values.expand((e) => e).toList());
    }
  }

  @override
  Future<void> saveKeyset(CahsuKeyset keyset) {
    if (cashuKeysets.containsKey(keyset.mintUrl)) {
      cashuKeysets[keyset.mintUrl]!.add(keyset);
    } else {
      cashuKeysets[keyset.mintUrl] = {keyset};
    }
    return Future.value();
  }

  @override
  Future<List<CashuProof>> getProofs({
    String? mintUrl,
    String? keysetId,
    CashuProofState state = CashuProofState.unspend,
  }) async {
    if (cashuProofs.containsKey(mintUrl)) {
      return cashuProofs[mintUrl]!
          .where((proof) =>
              proof.state == state &&
              (keysetId == null || proof.keysetId == keysetId))
          .toList();
    } else {
      return cashuProofs.values
          .expand((proofs) => proofs)
          .where((proof) =>
              proof.state == state &&
              (keysetId == null || proof.keysetId == keysetId))
          .toList();
    }
  }

  @override
  Future<void> saveProofs({
    required List<CashuProof> proofs,
    required String mintUrl,
  }) {
    if (cashuProofs.containsKey(mintUrl)) {
      cashuProofs[mintUrl]!.addAll(proofs);
    } else {
      cashuProofs[mintUrl] = Set<CashuProof>.from(proofs);
    }
    return Future.value();
  }

  @override
  Future<void> removeProofs(
      {required List<CashuProof> proofs, required String mintUrl}) {
    if (cashuProofs.containsKey(mintUrl)) {
      final existingProofs = cashuProofs[mintUrl]!;
      for (final proof in proofs) {
        existingProofs.removeWhere((p) => p.secret == proof.secret);
      }
      if (existingProofs.isEmpty) {
        cashuProofs.remove(mintUrl);
      }

      return Future.value();
    } else {
      return Future.error('No proofs found for mint URL: $mintUrl');
    }
  }

  @override
  Future<List<WalletTransaction>> getTransactions({
    int? limit,
    int? offset,
    String? walletId,
    String? unit,
    WalletType? walletType,
  }) {
    List<WalletTransaction> result = transactions.where((transaction) {
      if (walletId != null && transaction.walletId != walletId) {
        return false;
      }
      if (unit != null && transaction.unit != unit) {
        return false;
      }
      if (walletType != null && transaction.walletType != walletType) {
        return false;
      }
      return true;
    }).toList();

    if (offset != null && offset > 0) {
      result = result.skip(offset).toList();
    }

    if (limit != null && limit > 0) {
      result = result.take(limit).toList();
    }

    return Future.value(result);
  }

  @override
  Future<void> saveTransactions(
      {required List<WalletTransaction> transactions}) {
    /// Check if transactions are already present
    /// if so update them

    for (final transaction in transactions) {
      final existingIndex = this.transactions.indexWhere(
          (t) => t.id == transaction.id && t.walletId == transaction.walletId);
      if (existingIndex != -1) {
        this.transactions[existingIndex] = transaction;
      } else {
        this.transactions.add(transaction);
      }
    }
    return Future.value();
  }

  @override
  Future<List<Wallet>?> getWallets({List<String>? ids}) {
    if (ids == null || ids.isEmpty) {
      return Future.value(wallets.toList());
    } else {
      final result =
          wallets.where((wallet) => ids.contains(wallet.id)).toList();
      return Future.value(result.isNotEmpty ? result : null);
    }
  }

  @override
  Future<void> removeWallet(String id) {
    wallets.removeWhere((wallet) => wallet.id == id);
    return Future.value();
  }

  @override
  Future<void> saveWallet(Wallet wallet) {
    wallets.add(wallet);
    return Future.value();
  }

  @override
  Future<List<CashuMintInfo>?> getMintInfos({
    List<String>? mintUrls,
  }) {
    if (mintUrls == null) {
      return Future.value(cashuMintInfos.toList());
    } else {
      final result = cashuMintInfos
          .where(
            (info) => mintUrls.any((url) => info.isMintUrl(url)),
          )
          .toList();
      return Future.value(result.isNotEmpty ? result : null);
    }
  }

  @override
  Future<void> saveMintInfo({
    required CashuMintInfo mintInfo,
  }) {
    cashuMintInfos
        .removeWhere((info) => info.urls.any((url) => mintInfo.isMintUrl(url)));
    cashuMintInfos.add(mintInfo);
    return Future.value();
  }

  @override
  Future<int> getCashuSecretCounter({
    required String mintUrl,
    required String keysetId,
  }) {
    final key = '$mintUrl|$keysetId';
    return Future.value(_cashuSecretCounters[key] ?? 0);
  }

  @override
  Future<void> setCashuSecretCounter({
    required String mintUrl,
    required String keysetId,
    required int counter,
  }) async {
    final key = '$mintUrl|$keysetId';
    _cashuSecretCounters[key] = counter;

    return;
  }
}
