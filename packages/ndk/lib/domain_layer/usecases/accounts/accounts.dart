import 'package:ndk/data_layer/repositories/signers/nip46_event_signer.dart';

import '../../../data_layer/repositories/signers/bip340_event_signer.dart';
import '../../entities/account.dart';
import '../../entities/nip_01_event.dart';
import '../../repositories/event_signer.dart';

/// A usecase that handles accounts
class Accounts {
  /// pubKey -> Account
  final Map<String, Account> accounts = {};
  String? _loggedPubkey;

  /// adds a new Account and sets the logged pubkey
  void loginPrivateKey({required String pubkey, required String privkey}) {
    if (accounts.containsKey(pubkey)) {
      throw Exception("Cannot login, pubkey already logged in");
    }
    addAccount(
        pubkey: pubkey,
        type: AccountType.privateKey,
        signer: Bip340EventSigner(privateKey: privkey, publicKey: pubkey));
    _loggedPubkey = pubkey;
  }

  /// do we have the account for this pubkey?
  bool hasAccount(String pubkey) {
    return accounts.containsKey(pubkey);
  }

  /// adds a new read-only Account and sets the logged pubkey
  void loginPublicKey({required String pubkey}) {
    if (accounts.containsKey(pubkey)) {
      throw Exception("Cannot login, pubkey already logged in");
    }
    addAccount(
        pubkey: pubkey,
        type: AccountType.publicKey,
        signer: Bip340EventSigner(privateKey: null, publicKey: pubkey));
    _loggedPubkey = pubkey;
  }

  /// adds a new read-only Account and sets the logged pubkey
  void loginExternalSigner({required EventSigner signer}) {
    final pubkey = signer.getPublicKey();
    if (accounts.containsKey(pubkey)) {
      throw Exception("Cannot login, pubkey already logged in");
    }
    addAccount(
        pubkey: pubkey, type: AccountType.externalSigner, signer: signer);
    _loggedPubkey = pubkey;
  }

  /// adds a new Account and sets the logged pubkey
  Future<ConnectionSettings> loginWithBunkerUrl({required String bunkerUrl}) async {
    final bunkerLogin = BunkerLogin(bunkerUrl: bunkerUrl);
    ConnectionSettings? settings;
    await for (final event in bunkerLogin.stream) {
      if (event is Connected) {
        settings = event.settings;
        break;
      }
    }
    bunkerLogin.dispose();
    await loginWithBunker(settings: settings!);
    return settings;
  }

  /// adds a new Account and sets the logged pubkey
  Future<void> loginWithBunker({required ConnectionSettings settings}) async {
    final signer = Nip46EventSigner(connectionSettings: settings);
    await signer.getPublicKeyAsync();
    loginExternalSigner(signer: signer);
  }

  void logout() {
    if (_loggedPubkey != null) {
      accounts.remove(_loggedPubkey);
      _loggedPubkey = null;
    }
  }

  /// set logged account
  void switchAccount({required String pubkey}) {
    if (pubkey.isNotEmpty && accounts.containsKey(pubkey)) {
      _loggedPubkey = pubkey;
    } else {
      throw Exception("unknown account for pubkey");
    }
  }

  /// adds an Account
  void addAccount(
      {required String pubkey,
      required AccountType type,
      required EventSigner signer}) {
    accounts[pubkey] = Account(type: type, pubkey: pubkey, signer: signer);
  }

  // /// clears the logged pubkey
  void _clearLoggedPubkey() {
    _loggedPubkey = null;
  }

  /// removes an Account
  void removeAccount({required String pubkey}) {
    if (_loggedPubkey == pubkey) {
      _clearLoggedPubkey();
    }
    accounts.remove(pubkey);
  }

  /// low-level method, should not be used directly in most cases, use broadcast instead which calls signing on the signer
  Future<void> sign(Nip01Event event) async {
    Account? account = getLoggedAccount();
    if (account != null && account.signer.canSign()) {
      return account.signer.sign(event);
    }
    throw Exception("Cannot sign");
  }

  /// returns currently logged in account
  Account? getLoggedAccount() {
    return _loggedPubkey != null ? accounts[_loggedPubkey] : null;
  }

  /// is currently logged in account able to sign events
  bool get canSign {
    Account? account = getLoggedAccount();
    return account != null && account.signer.canSign();
  }

  bool get cannotSign => !canSign;

  /// is logged in
  bool get isLoggedIn => getLoggedAccount() != null;

  /// is not logged in
  bool get isNotLoggedIn => !isLoggedIn;

  /// returns public key of currently logged in account or null if not logged in
  String? getPublicKey() {
    return getLoggedAccount()?.pubkey;
  }
}
