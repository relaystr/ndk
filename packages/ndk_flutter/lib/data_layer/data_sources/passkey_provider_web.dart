import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:ndk/ndk.dart';
import 'passkey_response.dart';

/// Uses browser WebAuthn directly, including PRF extension buffers.
class PlatformPasskeyProvider implements PasskeyProvider {
  JSObject get _credentials => globalContext
      .getProperty<JSObject>('navigator'.toJS)
      .getProperty<JSObject>('credentials'.toJS);

  @override
  Future<PasskeyCredential> register({
    required String rpId,
    required String rpName,
    required String userName,
    required Uint8List challenge,
    required Uint8List userId,
    required Uint8List prfInput,
    List<Uint8List> excludeCredentialIds = const [],
  }) async {
    final options = {
      'publicKey': {
        'challenge': challenge.toJS,
        'rp': {'id': rpId, 'name': rpName},
        'user': {'id': userId.toJS, 'name': userName, 'displayName': userName},
        'pubKeyCredParams': [
          {'type': 'public-key', 'alg': -7},
        ],
        'authenticatorSelection': {
          'residentKey': 'required',
          'requireResidentKey': true,
          'userVerification': 'required',
        },
        'excludeCredentials': [
          for (final id in excludeCredentialIds)
            {'type': 'public-key', 'id': id.toJS},
        ],
        'attestation': 'none',
        'extensions': {
          'prf': {
            'eval': {'first': prfInput.toJS},
          },
        },
      },
    }.jsify();
    final credential = await _credentials
        .callMethod<JSPromise<JSObject?>>('create'.toJS, options)
        .toDart;
    return _result(credential, challenge, 'webauthn.create');
  }

  @override
  Future<PasskeyCredential> authenticate({
    required String rpId,
    required Uint8List challenge,
    required Uint8List? prfInput,
    Uint8List? credentialId,
  }) async {
    final options = {
      'publicKey': {
        'rpId': rpId,
        'challenge': challenge.toJS,
        'userVerification': 'required',
        if (credentialId != null)
          'allowCredentials': [
            {'type': 'public-key', 'id': credentialId.toJS},
          ],
        if (prfInput != null)
          'extensions': {
            'prf': {
              'eval': {'first': prfInput.toJS},
            },
          },
      },
    }.jsify();
    final credential = await _credentials
        .callMethod<JSPromise<JSObject?>>('get'.toJS, options)
        .toDart;
    if (credential != null) {
      final response = credential.getProperty<JSObject>('response'.toJS);
      validatePasskeyAuthData(_bytes(response, 'authenticatorData'), rpId);
    }
    return _result(credential, challenge, 'webauthn.get');
  }

  PasskeyCredential _result(
    JSObject? credential,
    Uint8List challenge,
    String type,
  ) {
    if (credential == null) throw StateError('No passkey credential returned');
    final response = credential.getProperty<JSObject>('response'.toJS);
    validatePasskeyClientData(
      base64Url.encode(_bytes(response, 'clientDataJSON')),
      challenge,
      type,
    );
    final extensions = credential.callMethod<JSObject>(
      'getClientExtensionResults'.toJS,
    );
    final prf = extensions.getProperty<JSObject?>('prf'.toJS);
    final results = prf?.getProperty<JSObject?>('results'.toJS);
    final first = results?.getProperty<JSArrayBuffer?>('first'.toJS);
    final enabled = prf?.getProperty<JSBoolean?>('enabled'.toJS);
    final handle = type == 'webauthn.get'
        ? response.getProperty<JSArrayBuffer?>('userHandle'.toJS)
        : null;
    return passkeyCredential(
      base64Url.encode(_bytes(credential, 'rawId')),
      {
        if (prf != null)
          'prf': {
            if (enabled != null) 'enabled': enabled.toDart,
            if (first != null)
              'results': {
                'first': base64Url.encode(first.toDart.asUint8List()),
              },
          },
      },
      userHandle: handle == null
          ? null
          : base64Url.encode(handle.toDart.asUint8List()),
    );
  }

  Uint8List _bytes(JSObject object, String property) =>
      object.getProperty<JSArrayBuffer>(property.toJS).toDart.asUint8List();
}
