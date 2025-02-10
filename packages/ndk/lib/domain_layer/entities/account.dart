import '../repositories/event_signer.dart';

enum AccountType { privateKey, publicKey, externalSigner }

/// Account entity
class Account {
  final AccountType type;
  final String pubkey;
  final EventSigner signer;

  Account({required this.type, required this.pubkey, required this.signer});
}
