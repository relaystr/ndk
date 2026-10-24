import 'dart:async';

import 'package:collection/collection.dart';
import 'package:rxdart/rxdart.dart';

import '../../entities/account.dart';
import '../../entities/passkey_account.dart';
import '../../repositories/passkey_provider.dart';
import '../passkeys/passkeys.dart';
import '../../entities/nip_01_event.dart';
import '../../repositories/event_signer.dart';
import '../bunkers/bunkers.dart';
import '../bunkers/models/bunker_connection.dart';
import '../../entities/nip46_client_metadata.dart';
import '../bunkers/models/nostr_connect.dart';

/// A usecase that handles accounts
class Accounts {
  /// Factory for creating EventSigner instances
  final LocalEventSignerFactory eventSignerFactory;

  final Map<String, Account> _accounts = {};
  String? _loggedPubkey;
  int _passkeyGeneration = 0;
  bool _disposed = false;

  static const _accountsEquality = MapEquality<String, Account>();

  /// Stream controller for authentication state changes
  final _stateController = BehaviorSubject<Account?>();

  /// Stream controller for the known accounts
  final _accountsController = BehaviorSubject<Map<String, Account>>.seeded(
    UnmodifiableMapView(<String, Account>{}),
  );

  /// Creates a new Accounts instance with the given event signer factory
  Accounts(this.eventSignerFactory);

  /// pubKey -> Account, read-only view, listen to [accountsStream] for changes
  /// Same instance until the accounts actually change, so every mutation of
  /// [_accounts] has to go through [_notifyAccountsChange]
  Map<String, Account> get accounts => _accountsController.value;

  /// Stream of authentication state changes
  /// Emits the current Account when logged in, or null when logged out
  Stream<Account?> get authStateChanges => _stateController.stream;

  /// Stream of the known accounts, pubKey -> Account
  /// Emits the current accounts on subscription, then an unmodifiable snapshot
  /// every time an account is added, replaced or removed
  Stream<Map<String, Account>> get accountsStream => _accountsController.stream;

  /// adds a new Account and sets the logged pubkey
  void loginPrivateKey({required String pubkey, required String privkey}) {
    if (_accounts.containsKey(pubkey)) {
      throw Exception("Cannot login, pubkey already logged in");
    }
    addAccount(
      pubkey: pubkey,
      type: AccountType.privateKey,
      signer: eventSignerFactory.create(privateKey: privkey, publicKey: pubkey),
    );
    _loggedPubkey = pubkey;
    _notifyAuthStateChange();
  }

  /// Creates a discoverable passkey and logs in with its PRF-derived Nostr key.
  /// Store only the returned public metadata; the signer holds the key in memory.
  Future<PasskeyAccount> createPasskey({
    required PasskeyProvider provider,
    required String rpId,
    required String rpName,
    required String userName,
    int parameterSet = 1,
  }) async {
    final generation = _beginPasskey();
    final result = await Passkeys(eventSignerFactory, provider).create(
      rpId: rpId,
      rpName: rpName,
      userName: userName,
      parameterSet: parameterSet,
    );
    return _completePasskey(result, generation);
  }

  /// Reopens an existing or synced passkey without ever creating a replacement.
  /// Omit [account] for discovery, or supply it to enforce the expected identity.
  Future<PasskeyAccount> loginWithPasskey({
    required PasskeyProvider provider,
    required String rpId,
    PasskeyAccount? account,
    PasskeyRecordResolver? resolveRecords,
    void Function(int candidateIndex, String reason)? onRecordFailure,
  }) async {
    final generation = _beginPasskey();
    final result = await Passkeys(eventSignerFactory, provider).reopen(
      rpId: rpId,
      account: account,
      resolveRecords: resolveRecords,
      onRecordFailure: onRecordFailure,
    );
    return _completePasskey(result, generation);
  }

  /// Protects an existing key and saves its encrypted record before login.
  Future<PasskeyAccount> createStoredPasskey({
    required PasskeyProvider provider,
    required String rpId,
    required String rpName,
    required String userName,
    required String privateKey,
    required bool hasVerifiedRecoveryCopy,
    required PasskeyRecordWriter saveRecord,
    required PasskeyCredentialInventory existingCredentialIds,
  }) async {
    final generation = _beginPasskey();
    final result = await Passkeys(eventSignerFactory, provider).createStored(
      rpId: rpId,
      rpName: rpName,
      userName: userName,
      privateKey: privateKey,
      hasVerifiedRecoveryCopy: hasVerifiedRecoveryCopy,
      saveRecord: saveRecord,
      existingCredentialIds: existingCredentialIds,
    );
    return _completePasskey(result, generation, preserveExisting: true);
  }

  int _beginPasskey() {
    if (_disposed) throw StateError('Accounts is disposed');
    return ++_passkeyGeneration;
  }

  Future<PasskeyAccount> _completePasskey(
    ({PasskeyAccount account, EventSigner signer}) result,
    int generation, {
    bool preserveExisting = false,
  }) async {
    var preserved = false;
    try {
      if (_disposed || generation != _passkeyGeneration) {
        throw StateError('Passkey operation was superseded');
      }
      preserved =
          preserveExisting && _accounts.containsKey(result.account.pubkey);
      if (!preserved) {
        loginExternalSigner(signer: result.signer);
      }
    } catch (_) {
      await result.signer.dispose();
      rethrow;
    }
    if (preserved) {
      await result.signer.dispose();
    }
    return result.account;
  }

  /// do we have the account for this pubkey?
  bool hasAccount(String pubkey) {
    return _accounts.containsKey(pubkey);
  }

  /// adds a new read-only Account and sets the logged pubkey
  void loginPublicKey({required String pubkey}) {
    if (_accounts.containsKey(pubkey)) {
      throw Exception("Cannot login, pubkey already logged in");
    }
    addAccount(
      pubkey: pubkey,
      type: AccountType.publicKey,
      signer: eventSignerFactory.create(privateKey: null, publicKey: pubkey),
    );
    _loggedPubkey = pubkey;
    _notifyAuthStateChange();
  }

  /// adds a new read-only Account and sets the logged pubkey
  void loginExternalSigner({required EventSigner signer}) {
    final pubkey = signer.getPublicKey();
    if (_accounts.containsKey(pubkey)) {
      throw Exception("Cannot login, pubkey already logged in");
    }
    addAccount(
      pubkey: pubkey,
      type: AccountType.externalSigner,
      signer: signer,
    );
    _loggedPubkey = pubkey;
    _notifyAuthStateChange();
  }

  Future<BunkerConnection?> loginWithBunkerUrl({
    required String bunkerUrl,
    required Bunkers bunkers,
    Function(String)? authCallback,
    Nip46ClientMetadata? clientMetadata,
  }) async {
    BunkerConnection? connection = await bunkers.connectWithBunkerUrl(
      bunkerUrl,
      authCallback: authCallback,
      clientMetadata: clientMetadata,
    );
    if (connection != null) {
      await loginWithBunkerConnection(
        connection: connection,
        bunkers: bunkers,
        authCallback: authCallback,
      );
    }
    return connection;
  }

  Future<BunkerConnection?> loginWithNostrConnect({
    required NostrConnect nostrConnect,
    required Bunkers bunkers,
    Function(String)? authCallback,
  }) async {
    BunkerConnection? connection = await bunkers.connectWithNostrConnect(
      nostrConnect,
      authCallback: authCallback,
    );
    if (connection != null) {
      await loginWithBunkerConnection(
        connection: connection,
        bunkers: bunkers,
        authCallback: authCallback,
      );
    }
    return connection;
  }

  Future<void> loginWithBunkerConnection({
    required BunkerConnection connection,
    required Bunkers bunkers,
    Function(String)? authCallback,
  }) async {
    final signer = bunkers.createSigner(connection, authCallback: authCallback);
    await signer.getPublicKeyAsync();
    loginExternalSigner(signer: signer);
  }

  void logout() {
    _passkeyGeneration++;
    if (_loggedPubkey != null) {
      _accounts.remove(_loggedPubkey);
      _loggedPubkey = null;
      _notifyAccountsChange();
      _notifyAuthStateChange();
    }
  }

  /// set logged account
  void switchAccount({required String pubkey}) {
    if (pubkey.isNotEmpty && _accounts.containsKey(pubkey)) {
      _loggedPubkey = pubkey;
      _notifyAuthStateChange();
    } else {
      throw Exception("unknown account for pubkey");
    }
  }

  /// adds an Account
  void addAccount({
    required String pubkey,
    required AccountType type,
    required EventSigner signer,
  }) {
    _accounts[pubkey] = Account(type: type, pubkey: pubkey, signer: signer);
    _notifyAccountsChange();
  }

  /// removes an Account
  void removeAccount({required String pubkey}) {
    final wasLoggedIn = _loggedPubkey == pubkey;
    if (wasLoggedIn) {
      _loggedPubkey = null;
    }
    _accounts.remove(pubkey);
    _notifyAccountsChange();
    if (wasLoggedIn) {
      _notifyAuthStateChange();
    }
  }

  /// low-level method, should not be used directly in most cases, use broadcast instead which calls signing on the signer
  Future<Nip01Event> sign(Nip01Event event) async {
    Account? account = getLoggedAccount();
    if (account != null && account.signer.canSign()) {
      return account.signer.sign(event);
    }
    throw Exception("Cannot sign");
  }

  /// returns currently logged in account
  Account? getLoggedAccount() {
    return _loggedPubkey != null ? _accounts[_loggedPubkey] : null;
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

  /// Notifies listeners of auth state changes
  void _notifyAuthStateChange() {
    _passkeyGeneration++;
    _stateController.add(getLoggedAccount());
  }

  /// Notifies listeners of accounts changes, no-op if nothing actually changed
  void _notifyAccountsChange() {
    if (_accountsEquality.equals(_accountsController.value, _accounts)) {
      return;
    }
    _passkeyGeneration++;
    _accountsController.add(UnmodifiableMapView(Map.of(_accounts)));
  }

  /// Dispose of resources
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _passkeyGeneration++;
    await _stateController.close();
    await _accountsController.close();
  }
}
