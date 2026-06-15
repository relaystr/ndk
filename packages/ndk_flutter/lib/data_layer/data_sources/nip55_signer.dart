import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:ndk/ndk.dart';

/// A permission that can be requested when logging in with a NIP-55 external
/// signer, so the signer can pre-authorize silent (ContentResolver) responses.
///
/// See https://github.com/nostr-protocol/nips/blob/master/55.md
class Nip55Permission {
  const Nip55Permission({required this.type, this.kind});

  /// The request type to authorize, e.g. `sign_event`, `nip04_encrypt`.
  final String type;

  /// Optional event kind, only relevant for `sign_event`.
  final int? kind;

  Map<String, dynamic> toJson() {
    return {'type': type, if (kind != null) 'kind': kind};
  }
}

/// Result of a NIP-55 login (`get_public_key`).
class Nip55LoginResult {
  const Nip55LoginResult({required this.pubkey, this.package});

  /// The user's public key, in hex format.
  final String pubkey;

  /// The signer app package name (e.g. Amber, Primal), if the signer returned
  /// it. Used to target the same signer for subsequent requests.
  final String? package;
}

/// Dart bridge to a NIP-55 "Android Signer Application".
///
/// NIP-55 is a protocol implemented by several external signer apps
/// (Amber, Primal, Aegis, ...). This class talks to whichever compatible
/// signer is installed through the native `ndk` method channel
/// ([DartNdkPlugin]).
///
/// Every method resolves to a `Map` that contains (at least) a `signature`
/// key with the result, mirroring the historical `amberflutter` API.
class Nip55Signer {
  /// The method channel shared with the native [DartNdkPlugin].
  static const MethodChannel _channel = MethodChannel('ndk');

  /// Default permissions requested at login so common operations can be
  /// answered silently (via ContentResolver) without reopening the signer.
  static const List<Nip55Permission> defaultPermissions = [
    Nip55Permission(type: 'sign_event'),
    Nip55Permission(type: 'nip04_encrypt'),
    Nip55Permission(type: 'nip04_decrypt'),
    Nip55Permission(type: 'nip44_encrypt'),
    Nip55Permission(type: 'nip44_decrypt'),
  ];

  /// The signer app package (e.g. Amber, Primal), captured at login. Used to
  /// target the right signer for both the ContentResolver and the Intent.
  /// When `null`, the native side lets Android route through a compatible
  /// signer app.
  final String? package;

  const Nip55Signer({this.package});

  /// Whether a NIP-55 compatible external signer is installed.
  Future<bool> isAppInstalled() async {
    final data = await _channel.invokeMethod<bool>('isAppInstalled');
    return data ?? false;
  }

  /// Requests the user's public key (login). Optionally pre-authorizes
  /// [permissions] so subsequent requests can be answered silently.
  ///
  /// Returns the raw signer response map. Most callers want
  /// [getPublicKeyHex] instead.
  Future<Map<dynamic, dynamic>> getPublicKey({
    List<Nip55Permission>? permissions,
  }) async {
    final arguments = <String, dynamic>{
      'type': 'get_public_key',
      'uri_data': 'login',
    };
    if (permissions != null) {
      arguments['permissions'] = jsonEncode(permissions);
    }
    return _invoke(arguments);
  }

  /// Requests the user's public key and returns it as a hex pubkey, or `null`
  /// if the user rejected or no key was returned.
  ///
  /// NIP-55 returns the key in the `result` field, in hex format. Older
  /// signers (and Amber legacy) may return an npub instead, so both are
  /// accepted. See https://github.com/nostr-protocol/nips/blob/master/55.md
  Future<String?> getPublicKeyHex({List<Nip55Permission>? permissions}) async {
    return (await login(permissions: permissions))?.pubkey;
  }

  /// Logs in: requests the user's public key, pre-authorizing [permissions]
  /// (defaults to [defaultPermissions]), and captures the signer app package.
  /// Returns `null` if the user rejected or no key was returned.
  Future<Nip55LoginResult?> login({List<Nip55Permission>? permissions}) async {
    final response = await getPublicKey(
      permissions: permissions ?? defaultPermissions,
    );
    final raw = (response['result'] ?? response['signature']) as String?;
    if (raw == null || raw.isEmpty) return null;
    final pubkey = raw.startsWith('npub') ? Nip19.decode(raw) : raw;
    final pkg = response['package'] as String?;
    return Nip55LoginResult(
      pubkey: pubkey,
      package: (pkg != null && pkg.isNotEmpty) ? pkg : null,
    );
  }

  Future<Map<dynamic, dynamic>> signEvent({
    required String currentUser,
    required String eventJson,
    String? id,
  }) {
    return _invoke({
      'type': 'sign_event',
      'current_user': currentUser,
      'uri_data': eventJson,
      'id': id,
    });
  }

  Future<Map<dynamic, dynamic>> nip04Encrypt({
    required String plaintext,
    required String currentUser,
    required String pubKey,
    String? id,
  }) {
    return _invoke(
      _encryptArgs('nip04_encrypt', plaintext, currentUser, pubKey, id),
    );
  }

  Future<Map<dynamic, dynamic>> nip04Decrypt({
    required String ciphertext,
    required String currentUser,
    required String pubKey,
    String? id,
  }) {
    return _invoke(
      _encryptArgs('nip04_decrypt', ciphertext, currentUser, pubKey, id),
    );
  }

  Future<Map<dynamic, dynamic>> nip44Encrypt({
    required String plaintext,
    required String currentUser,
    required String pubKey,
    String? id,
  }) {
    return _invoke(
      _encryptArgs('nip44_encrypt', plaintext, currentUser, pubKey, id),
    );
  }

  Future<Map<dynamic, dynamic>> nip44Decrypt({
    required String ciphertext,
    required String currentUser,
    required String pubKey,
    String? id,
  }) {
    return _invoke(
      _encryptArgs('nip44_decrypt', ciphertext, currentUser, pubKey, id),
    );
  }

  Future<Map<dynamic, dynamic>> decryptZapEvent({
    required String eventJson,
    required String currentUser,
    String? id,
  }) {
    return _invoke({
      'type': 'decrypt_zap_event',
      'uri_data': eventJson,
      'current_user': currentUser,
      'id': id,
    });
  }

  Map<String, dynamic> _encryptArgs(
    String type,
    String uriData,
    String currentUser,
    String pubKey,
    String? id,
  ) {
    return {
      'type': type,
      'uri_data': uriData,
      'current_user': currentUser,
      // both casings are sent to stay compatible with signer implementations
      'pubKey': pubKey,
      'pubkey': pubKey,
      'id': id,
    };
  }

  Future<Map<dynamic, dynamic>> _invoke(Map<String, dynamic> arguments) async {
    // Target the signer captured at login (if any), so the request goes to the
    // right app and can be answered silently via its ContentResolver.
    if (package != null) {
      arguments['package'] = package;
    }
    final data = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'nostrsigner',
      arguments,
    );
    return data ?? {};
  }
}
