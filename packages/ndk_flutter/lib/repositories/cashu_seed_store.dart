import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ndk/domain_layer/entities/cashu/cashu_user_seedphrase.dart';
import 'package:ndk/ndk.dart';

/// Loads the cashu user seed phrase from platform secure storage
/// (Keychain / Keystore), generating and persisting a fresh BIP39 seed phrase
/// on first run.
///
/// The seed phrase controls cashu funds — never hardcode it. It is written once
/// and reused on every subsequent launch so deterministic secrets keep matching
/// previously minted proofs.
///
/// Pass the result to [NdkConfig.cashuUserSeedphrase] via [CashuUserSeedphrase].
class CashuSeedStore {
  CashuSeedStore({FlutterSecureStorage? storage, String? storageKey})
    : _storage = storage ?? const FlutterSecureStorage(),
      _seedKey = storageKey ?? _defaultSeedKey;

  final FlutterSecureStorage _storage;
  final String _seedKey;

  static const String _defaultSeedKey = 'ndk_flutter_cashu_seed_phrase';
  static const String _backedUpKey = '${_defaultSeedKey}_backed_up';

  /// Returns the stored seed phrase, or generates, persists and returns a new
  /// one if none exists yet.
  Future<String> loadOrCreate() async {
    final existing = await _storage.read(key: _seedKey);
    if (existing != null && existing.trim().isNotEmpty) {
      return existing;
    }

    final fresh = CashuSeed.generateSeedPhrase(length: MnemonicLength.words12);
    await _storage.write(key: _seedKey, value: fresh);
    return fresh;
  }

  /// Reads the stored seed phrase without generating one. Returns null if none
  /// has been stored yet.
  Future<String?> read() => _storage.read(key: _seedKey);

  /// Overwrites the stored seed phrase, e.g. when restoring from a backup.
  Future<void> write(String seedPhrase) =>
      _storage.write(key: _seedKey, value: seedPhrase);

  /// Whether the user confirmed they have safely backed up the seed phrase.
  Future<bool> isBackedUp() async =>
      (await _storage.read(key: _backedUpKey)) == 'true';

  /// Records whether the user has backed up the seed phrase.
  Future<void> setBackedUp(bool value) =>
      _storage.write(key: _backedUpKey, value: value ? 'true' : 'false');
}
