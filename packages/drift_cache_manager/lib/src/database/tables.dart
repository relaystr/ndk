import 'package:drift/drift.dart';

/// Table for storing Nostr events (NIP-01)
@DataClassName('DbEvent')
class Events extends Table {
  TextColumn get id => text()();
  TextColumn get pubKey => text()();
  IntColumn get kind => integer()();
  IntColumn get createdAt => integer()();
  TextColumn get content => text()();
  TextColumn get sig => text().nullable()();
  BoolColumn get validSig => boolean().nullable()();
  TextColumn get tagsJson => text()(); // JSON encoded tags
  TextColumn get sourcesJson => text()(); // JSON encoded sources

  @override
  Set<Column> get primaryKey => {id};
}

/// Table for storing user metadata (NIP-01 kind 0)
@DataClassName('DbMetadata')
class Metadatas extends Table {
  TextColumn get pubKey => text()();
  TextColumn get name => text().nullable()();
  TextColumn get displayName => text().nullable()();
  TextColumn get picture => text().nullable()();
  TextColumn get banner => text().nullable()();
  TextColumn get website => text().nullable()();
  TextColumn get about => text().nullable()();
  TextColumn get nip05 => text().nullable()();
  TextColumn get lud16 => text().nullable()();
  TextColumn get lud06 => text().nullable()();
  IntColumn get updatedAt => integer().nullable()();
  IntColumn get refreshedTimestamp => integer().nullable()();
  TextColumn get sourcesJson => text()(); // JSON encoded sources
  TextColumn get tagsJson =>
      text().withDefault(const Constant('[]'))(); // JSON encoded tags
  TextColumn get rawContentJson =>
      text().nullable()(); // JSON encoded rawContent

  @override
  Set<Column> get primaryKey => {pubKey};
}

/// Table for storing contact lists (NIP-02)
@DataClassName('DbContactList')
class ContactLists extends Table {
  TextColumn get pubKey => text()();
  TextColumn get contactsJson => text()(); // JSON encoded contacts
  TextColumn get contactRelaysJson => text()(); // JSON encoded contact relays
  TextColumn get petnamesJson => text()(); // JSON encoded petnames
  TextColumn get followedTagsJson => text()(); // JSON encoded followed tags
  TextColumn get followedCommunitiesJson =>
      text()(); // JSON encoded followed communities
  TextColumn get followedEventsJson => text()(); // JSON encoded followed events
  IntColumn get createdAt => integer()();
  IntColumn get loadedTimestamp => integer().nullable()();
  TextColumn get sourcesJson => text()(); // JSON encoded sources

  @override
  Set<Column> get primaryKey => {pubKey};
}

/// Table for storing user relay lists (NIP-65)
@DataClassName('DbUserRelayList')
class UserRelayLists extends Table {
  TextColumn get pubKey => text()();
  IntColumn get createdAt => integer()();
  IntColumn get refreshedTimestamp => integer()();
  TextColumn get relaysJson => text()(); // JSON encoded relays map

  @override
  Set<Column> get primaryKey => {pubKey};
}

/// Table for storing relay sets
@DataClassName('DbRelaySet')
class RelaySets extends Table {
  TextColumn get id => text()(); // Composite key: name,pubKey
  TextColumn get name => text()();
  TextColumn get pubKey => text()();
  IntColumn get relayMinCountPerPubkey => integer()();
  IntColumn get direction => integer()(); // RelayDirection enum index
  TextColumn get relaysMapJson => text()(); // JSON encoded relays map
  BoolColumn get fallbackToBootstrapRelays => boolean()();
  TextColumn get notCoveredPubkeysJson =>
      text()(); // JSON encoded not covered pubkeys

  @override
  Set<Column> get primaryKey => {id};
}

/// Table for storing NIP-05 verification data
@DataClassName('DbNip05')
class Nip05s extends Table {
  TextColumn get pubKey => text()();
  TextColumn get nip05 => text()();
  BoolColumn get valid => boolean()();
  IntColumn get networkFetchTime => integer().nullable()();
  TextColumn get relaysJson => text()(); // JSON encoded relays

  @override
  Set<Column> get primaryKey => {pubKey};
}

/// Table for storing filter fetched range records
@DataClassName('DbFilterFetchedRangeRecord')
class FilterFetchedRangeRecords extends Table {
  TextColumn get key =>
      text()(); // Composite key: filterHash:relayUrl:rangeStart
  TextColumn get filterHash => text()();
  TextColumn get relayUrl => text()();
  IntColumn get rangeStart => integer()();
  IntColumn get rangeEnd => integer()();

  @override
  Set<Column> get primaryKey => {key};
}

// =====================
// Cashu Tables
// =====================

/// Table for storing Cashu proofs
@DataClassName('DbCashuProof')
class CashuProofs extends Table {
  TextColumn get Y => text()(); // Derived public key (unique identifier)
  TextColumn get keysetId => text()();
  IntColumn get amount => integer()();
  TextColumn get secret => text()();
  TextColumn get unblindedSig => text()();
  TextColumn get state => text()(); // UNSPENT, PENDING, SPENT
  TextColumn get mintUrl => text()();

  @override
  Set<Column> get primaryKey => {Y};
}

/// Table for storing Cashu keysets
@DataClassName('DbCashuKeyset')
class CashuKeysets extends Table {
  TextColumn get id => text()();
  TextColumn get mintUrl => text()();
  TextColumn get unit => text()();
  BoolColumn get active => boolean()();
  IntColumn get inputFeePPK => integer()();
  TextColumn get mintKeyPairsJson => text()(); // JSON encoded key pairs
  IntColumn get fetchedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id, mintUrl};
}

/// Table for storing Cashu mint info
@DataClassName('DbCashuMintInfo')
class CashuMintInfos extends Table {
  TextColumn get id => text()(); // Using first URL as ID
  TextColumn get urlsJson => text()(); // JSON encoded list of URLs
  TextColumn get name => text().nullable()();
  TextColumn get pubkey => text().nullable()();
  TextColumn get version => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get descriptionLong => text().nullable()();
  TextColumn get contactJson => text()(); // JSON encoded contact list
  TextColumn get motd => text().nullable()();
  TextColumn get iconUrl => text().nullable()();
  IntColumn get time => integer().nullable()();
  TextColumn get tosUrl => text().nullable()();
  TextColumn get nutsJson => text()(); // JSON encoded nuts map

  @override
  Set<Column> get primaryKey => {id};
}

/// Table for storing Cashu secret counters
@DataClassName('DbCashuSecretCounter')
class CashuSecretCounters extends Table {
  TextColumn get id => text()(); // Composite: mintUrl|keysetId
  TextColumn get mintUrl => text()();
  TextColumn get keysetId => text()();
  IntColumn get counter => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table for storing wallets
@DataClassName('DbWallet')
class Wallets extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text()(); // CASHU, NWC, etc.
  TextColumn get supportedUnitsJson => text()(); // JSON encoded set
  TextColumn get metadataJson => text()(); // JSON encoded metadata

  @override
  Set<Column> get primaryKey => {id};
}

/// Table for storing wallet transactions
@DataClassName('DbWalletTransaction')
class WalletTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get walletId => text()();
  IntColumn get changeAmount => integer()();
  TextColumn get unit => text()();
  TextColumn get type => text()(); // CASHU, NWC
  TextColumn get state =>
      text()(); // draft, pending, completed, canceled, failed
  TextColumn get completionMsg => text().nullable()();
  IntColumn get transactionDate => integer().nullable()();
  IntColumn get initiatedDate => integer().nullable()();
  TextColumn get metadataJson => text()(); // JSON encoded metadata

  @override
  Set<Column> get primaryKey => {id, walletId};
}
