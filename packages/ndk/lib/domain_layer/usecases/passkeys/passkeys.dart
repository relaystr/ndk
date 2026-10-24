import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:convert/convert.dart';
import 'package:cryptography/cryptography.dart';
import 'package:pointycastle/ecc/curves/secp256k1.dart';

import '../../entities/passkey_account.dart';
import '../../repositories/event_signer.dart';
import '../../repositories/passkey_provider.dart';

/// Host storage adapters receive public metadata, never PRF outputs or keys.
/// A relay adapter must validate signatures, author, exact credential :key d tag,
/// kind 31778, absence of v tags, canonical base64 and type 01 before returning
/// candidate bytes. Files must be explicitly selected by the user.
typedef PasskeyRecordResolver =
    Future<List<Uint8List>> Function(PasskeyAccount account);
typedef PasskeyRecordWriter =
    Future<void> Function(PasskeyAccount account, Uint8List record);

/// Must query validly signed kind 31778 events by this author and include every
/// credential named by their d tags plus locally known IDs, before creation.
typedef PasskeyCredentialInventory =
    Future<List<Uint8List>> Function(String rpId, String author);

/// NIP passkey-held key core. Vaults and legacy stored formats require an
/// explicit format-specific integration; they never fall back to derivation.
class Passkeys {
  final LocalEventSignerFactory signerFactory;
  final PasskeyProvider provider;
  Passkeys(this.signerFactory, this.provider);

  static final _order = ECCurve_secp256k1().n;
  static const _equal = ListEquality<int>();
  static const _store = 'nostr-passkey:store:v1';
  static final _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
  static final _aes = AesGcm.with256bits();

  Uint8List _random([int length = 32]) {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(length, (_) => random.nextInt(256)),
    );
  }

  static void _clear(Uint8List? bytes) => bytes?.fillRange(0, bytes.length, 0);
  static bool _prefix(List<int> bytes, List<int> prefix) =>
      bytes.length >= prefix.length &&
      _equal.equals(bytes.sublist(0, prefix.length), prefix);

  /// Ordered handle classification; raw 32-byte keys precede unsupported tags.
  static ({String mode, int? parameterSet, String? author}) classify(
    Uint8List? handle,
  ) {
    final h = handle ?? Uint8List(0);
    if (h.length == 22 && _prefix(h, [78, 80, 75, 1, 1])) {
      return (mode: 'derived', parameterSet: h[5], author: null);
    }
    if (h.length == 37 && _prefix(h, [78, 80, 75, 1, 2])) {
      return (
        mode: 'stored',
        parameterSet: null,
        author: hex.encode(h.sublist(5)),
      );
    }
    if (h.length == 32) {
      return (mode: 'legacyStored', parameterSet: null, author: hex.encode(h));
    }
    if (h.length == 33 && h[0] == 3) {
      return (mode: 'legacyKeyInHandle', parameterSet: null, author: null);
    }
    return (
      mode: _prefix(h, [78, 80, 75]) ? 'unsupported' : 'unknown',
      parameterSet: null,
      author: null,
    );
  }

  static Future<Uint8List> prfInput(String mode, [int? parameterSet]) async {
    if (mode == 'legacyNosskeyDirect') {
      return Uint8List.fromList(utf8.encode('nostr-pwk'));
    }
    final label = mode == 'stored'
        ? _store
        : switch (parameterSet) {
            1 => 'nostr-passkey:derive:v1',
            2 => 'lawallet-nsec-prf-v1',
            _ => throw UnsupportedError(
              'Another or newer app made this passkey',
            ),
          };
    return Uint8List.fromList((await Sha256().hash(utf8.encode(label))).bytes);
  }

  static Future<Uint8List> deriveKey(Uint8List output, int parameterSet) async {
    _checkPrf(output);
    final salt = await prfInput('derived', parameterSet);
    final key = await _hkdf.deriveKey(
      secretKey: SecretKey(output),
      nonce: salt,
      info: utf8.encode(
        parameterSet == 1 ? 'nostr-passkey:nsec:v1' : 'lawallet-nsec-v1',
      ),
    );
    final bytes = Uint8List.fromList(await key.extractBytes());
    _checkKey(bytes);
    return bytes;
  }

  Future<({PasskeyAccount account, EventSigner signer})> create({
    required String rpId,
    required String rpName,
    required String userName,
    int parameterSet = 1,
  }) async {
    final input = await prfInput('derived', parameterSet);
    final credential = await _register(
      rpId,
      rpName,
      userName,
      Uint8List.fromList([78, 80, 75, 1, 1, parameterSet, ..._random(16)]),
      input,
      [],
    );
    try {
      final secret = await deriveKey(credential.prfOutput!, parameterSet);
      try {
        return _signer(rpId, credential, secret, 'derived', parameterSet);
      } finally {
        _clear(secret);
      }
    } finally {
      _clear(credential.prfOutput);
    }
  }

  /// Protect an existing identity, completing persistence before returning a
  /// signer. A failed save propagates; the host should offer another location.
  Future<({PasskeyAccount account, EventSigner signer})> createStored({
    required String rpId,
    required String rpName,
    required String userName,
    required String privateKey,
    required bool hasVerifiedRecoveryCopy,
    required PasskeyRecordWriter saveRecord,
    required PasskeyCredentialInventory existingCredentialIds,
  }) async {
    if (!hasVerifiedRecoveryCopy) {
      throw StateError(
        'Verify an independent recovery copy before creating a stored passkey',
      );
    }
    final secret = Uint8List.fromList(hex.decode(privateKey));
    try {
      _checkKey(secret);
      PasskeyAccount.validateRpId(rpId);
      final author = signerFactory.derivePublicKey(hex.encode(secret));
      final excluded = await existingCredentialIds(rpId, author);
      if (excluded.any((id) => id.isEmpty || id.length > 1024)) {
        throw ArgumentError('Invalid excluded credential');
      }
      final credential = await _register(
        rpId,
        rpName,
        userName,
        Uint8List.fromList([78, 80, 75, 1, 2, ...hex.decode(author)]),
        await prfInput('stored'),
        excluded,
      );
      try {
        final account = PasskeyAccount(
          rpId: rpId,
          credentialId: credential.credentialId,
          pubkey: author,
          mode: 'stored',
        );
        final salt = _random();
        final iv = _random(12);
        final key = await _hkdf.deriveKey(
          secretKey: SecretKey(credential.prfOutput!),
          nonce: salt,
          info: utf8.encode(_store),
        );
        final box = await _aes.encrypt(
          secret,
          secretKey: key,
          nonce: iv,
          aad: _aad(account),
        );
        final record = Uint8List.fromList([
          78,
          80,
          75,
          1,
          1,
          ...iv,
          ...salt,
          ...box.cipherText,
          ...box.mac.bytes,
        ]);
        await saveRecord(account, record);
        return _signer(rpId, credential, secret, 'stored', null);
      } finally {
        _clear(credential.prfOutput);
      }
    } finally {
      _clear(secret);
    }
  }

  Future<PasskeyCredential> _register(
    String rp,
    String rpName,
    String userName,
    Uint8List handle,
    Uint8List input,
    List<Uint8List> excluded,
  ) async {
    PasskeyAccount.validateRpId(rp);
    if (rpName.trim().isEmpty || userName.trim().isEmpty) {
      throw ArgumentError('Passkey names must not be empty');
    }
    var credential = await provider.register(
      rpId: rp,
      rpName: rpName,
      userName: userName,
      challenge: _random(),
      userId: handle,
      prfInput: input,
      excludeCredentialIds: excluded,
    );
    try {
      _validateCredential(credential);
      if (credential.prfEnabled == false) {
        throw UnsupportedError('PRF unavailable; delete the unusable passkey');
      }
      if (credential.userHandle != null &&
          !_equal.equals(credential.userHandle, handle)) {
        throw StateError('Registration handle mismatch');
      }
      if (credential.prfOutput == null) {
        credential = await _evaluate(rp, credential, input);
      }
      if (credential.userHandle != null &&
          !_equal.equals(credential.userHandle, handle)) {
        throw StateError('Registration assertion handle mismatch');
      }
      _checkPrf(credential.prfOutput);
      return credential;
    } catch (_) {
      _clear(credential.prfOutput);
      rethrow;
    }
  }

  Future<({PasskeyAccount account, EventSigner signer})> reopen({
    required String rpId,
    PasskeyAccount? account,
    PasskeyRecordResolver? resolveRecords,
    void Function(int candidateIndex, String reason)? onRecordFailure,
  }) async {
    PasskeyAccount.validateRpId(rpId);
    if (account != null && account.rpId != rpId) {
      throw ArgumentError('Passkey belongs to another relying party');
    }
    var credential = await provider.authenticate(
      rpId: rpId,
      challenge: _random(),
      prfInput: null,
      credentialId: account?.credentialId,
    );
    try {
      _validateCredential(credential);
      if (account != null &&
          !_equal.equals(account.credentialId, credential.credentialId)) {
        throw StateError('Passkey credential mismatch');
      }
      final kind = classify(credential.userHandle);
      var mode = kind.mode;
      var parameter = kind.parameterSet;
      var author = kind.author;
      if (mode == 'unknown' &&
          account != null &&
          (account.mode == 'legacyNosskeyDirect' ||
              account.mode == 'derived')) {
        mode = account.mode;
        parameter = account.parameterSet;
      } else if (mode == 'unknown' &&
          credential.userHandle == null &&
          account?.mode == 'stored') {
        mode = 'stored';
        author = account!.pubkey;
      } else if (mode != 'derived' && mode != 'stored') {
        throw UnsupportedError(
          'Unknown or unsupported passkey; recover its original metadata or use its provider',
        );
      }
      if (account != null &&
          (account.mode != mode ||
              account.parameterSet != parameter ||
              (kind.author != null && kind.author != account.pubkey))) {
        throw StateError('Passkey metadata mismatch');
      }
      credential = await _evaluate(
        rpId,
        credential,
        await prfInput(mode, parameter),
      );
      Uint8List secret;
      if (mode == 'stored') {
        if (resolveRecords == null) {
          throw StateError('Stored passkey requires its encrypted record');
        }
        final metadata = PasskeyAccount(
          rpId: rpId,
          credentialId: credential.credentialId,
          pubkey: author!,
          mode: 'stored',
        );
        secret = await _openCandidates(
          metadata,
          credential.prfOutput!,
          await resolveRecords(metadata),
          onRecordFailure,
        );
      } else {
        secret = mode == 'derived'
            ? await deriveKey(credential.prfOutput!, parameter!)
            : Uint8List.fromList(credential.prfOutput!);
      }
      try {
        return _signer(
          rpId,
          credential,
          secret,
          mode,
          parameter,
          expected: account,
        );
      } finally {
        _clear(secret);
      }
    } finally {
      _clear(credential.prfOutput);
    }
  }

  Future<PasskeyCredential> _evaluate(
    String rp,
    PasskeyCredential previous,
    Uint8List input,
  ) async {
    final id = Uint8List.fromList(previous.credentialId);
    _clear(previous.prfOutput);
    final result = await provider.authenticate(
      rpId: rp,
      challenge: _random(),
      prfInput: input,
      credentialId: id,
    );
    try {
      _validateCredential(result);
      if (result.prfEnabled == false) {
        throw UnsupportedError('Passkey PRF unavailable');
      }
      if (!_equal.equals(id, result.credentialId) ||
          (previous.userHandle != null &&
              result.userHandle != null &&
              !_equal.equals(previous.userHandle, result.userHandle))) {
        throw StateError('Passkey credential changed');
      }
      _checkPrf(result.prfOutput);
      return result;
    } catch (_) {
      _clear(result.prfOutput);
      rethrow;
    }
  }

  static List<int> _aad(PasskeyAccount account) {
    final rp = ascii.encode(account.rpId.toLowerCase());
    return [
      78,
      80,
      75,
      1,
      1,
      rp.length,
      ...rp,
      ...hex.decode(account.pubkey),
      account.credentialId.length >> 8,
      account.credentialId.length & 255,
      ...account.credentialId,
    ];
  }

  Future<Uint8List> _openCandidates(
    PasskeyAccount account,
    Uint8List output,
    List<Uint8List> records,
    void Function(int, String)? onRecordFailure,
  ) async {
    for (var index = 0; index < records.length; index++) {
      final record = records[index];
      Uint8List? secret;
      try {
        // Key plaintext is exactly 32 bytes. Type 02 is reserved; vault type 03
        // requires a companion implementation and is deliberately not decoded.
        if (record.length != 97 || !_prefix(record, [78, 80, 75, 1, 1])) {
          onRecordFailure?.call(
            index,
            'Unsupported or malformed key record; vaults require a companion reader',
          );
          continue;
        }
        final key = await _hkdf.deriveKey(
          secretKey: SecretKey(output),
          nonce: record.sublist(17, 49),
          info: utf8.encode(_store),
        );
        secret = Uint8List.fromList(
          await _aes.decrypt(
            SecretBox(
              record.sublist(49, 81),
              nonce: record.sublist(5, 17),
              mac: Mac(record.sublist(81)),
            ),
            secretKey: key,
            aad: _aad(account),
          ),
        );
        _checkKey(secret);
        if (signerFactory.derivePublicKey(hex.encode(secret)) ==
            account.pubkey) {
          return secret;
        }
      } on SecretBoxAuthenticationError {
        // A failed candidate does not prevent another valid key record opening.
      } on StateError {
        // Invalid plaintext is not an identity.
      }
      _clear(secret);
      onRecordFailure?.call(
        index,
        'Record authentication, plaintext or author check failed',
      );
    }
    throw StateError(
      'No key record opened; missing, invalid or unsupported vault/legacy format',
    );
  }

  ({PasskeyAccount account, EventSigner signer}) _signer(
    String rp,
    PasskeyCredential credential,
    Uint8List secret,
    String mode,
    int? parameter, {
    PasskeyAccount? expected,
  }) {
    _checkKey(secret);
    final privateKey = hex.encode(secret);
    final pubkey = signerFactory.derivePublicKey(privateKey);
    if (expected != null && expected.pubkey != pubkey) {
      throw StateError('Passkey identity mismatch');
    }
    return (
      account: PasskeyAccount(
        rpId: rp,
        credentialId: credential.credentialId,
        pubkey: pubkey,
        mode: mode,
        parameterSet: parameter,
      ),
      signer: signerFactory.create(privateKey: privateKey, publicKey: pubkey),
    );
  }

  static void _checkPrf(Uint8List? output) {
    if (output == null) {
      throw UnsupportedError(
        'Passkey PRF unavailable; delete an unusable newly created passkey',
      );
    }
    if (output.length != 32) throw StateError('Invalid passkey PRF output');
  }

  static void _checkKey(Uint8List secret) {
    if (secret.length != 32) throw StateError('Invalid Nostr private key');
    final scalar = BigInt.parse(hex.encode(secret), radix: 16);
    if (scalar == BigInt.zero || scalar >= _order) {
      throw StateError('Invalid Nostr private key');
    }
  }

  static void _validateCredential(PasskeyCredential credential) {
    if (credential.credentialId.isEmpty ||
        credential.credentialId.length > 1024) {
      throw StateError('Invalid passkey credential ID');
    }
  }
}
