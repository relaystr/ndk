// ignore_for_file: constant_identifier_names

/// default indexer relays
///
/// aggregators that serve kind 10002 (nip65) for arbitrary pubkeys, unlike
/// general purpose relays which only hold the events of their own users \
/// kind 0 coverage is a bonus, metadata is reachable on the user own relays
/// once their nip65 list is known
const List<String> DEFAULT_INDEXER_RELAYS = [
  "wss://indexer.coracle.social", // nip65 only, no metadata
  "wss://directory.yabu.me",
  "wss://purplepag.es",
  "wss://relay.nos.social",
  // "wss://user.kindpag.es",
];
