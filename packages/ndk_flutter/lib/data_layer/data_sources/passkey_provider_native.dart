import 'dart:typed_data';

import 'package:ndk/ndk.dart';
import 'package:passkeys_platform_interface/passkeys_platform_interface.dart';
import 'package:passkeys_platform_interface/types/types.dart';
import 'passkey_response.dart';

/// Creates and authenticates passkeys through the platform credential provider.
///
/// The application must associate its Android/iOS app with the relying party's domain.
/// Passkey synchronization and PRF availability depend on the chosen provider.
class PlatformPasskeyProvider implements PasskeyProvider {
  PlatformPasskeyProvider({PasskeysPlatform? platform})
    : _platform = platform ?? PasskeysPlatform.instance;

  final PasskeysPlatform _platform;

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
    final response = await _platform.register(
      RegisterRequestType.fromJson({
        'challenge': encodePasskeyBytes(challenge),
        'rp': {'id': rpId, 'name': rpName},
        'user': {
          'id': encodePasskeyBytes(userId),
          'name': userName,
          'displayName': userName,
        },
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
            {
              'type': 'public-key',
              'id': encodePasskeyBytes(id),
              'transports': <String>[],
            },
        ],
        'attestation': 'none',
        'extensions': {
          'prf': {
            'eval': {'first': encodePasskeyBytes(prfInput)},
          },
        },
      }),
    );
    validatePasskeyClientData(
      response.clientDataJSON,
      challenge,
      'webauthn.create',
    );
    return passkeyCredential(response.rawId, response.clientExtensionResults);
  }

  @override
  Future<PasskeyCredential> authenticate({
    required String rpId,
    required Uint8List challenge,
    required Uint8List? prfInput,
    Uint8List? credentialId,
  }) async {
    final response = await _platform.authenticate(
      AuthenticateRequestType.fromJson(
        {
          'rpId': rpId,
          'challenge': encodePasskeyBytes(challenge),
          'userVerification': 'required',
          if (credentialId != null)
            'allowCredentials': [
              {
                'type': 'public-key',
                'id': encodePasskeyBytes(credentialId),
                'transports': <String>[],
              },
            ],
          if (prfInput != null)
            'extensions': {
              'prf': {
                'eval': {'first': encodePasskeyBytes(prfInput)},
              },
            },
        },
        preferImmediatelyAvailableCredentials: false,
        canBeSecurityKey: true,
      ),
    );
    validatePasskeyClientData(
      response.clientDataJSON,
      challenge,
      'webauthn.get',
    );
    validatePasskeyAuthData(
      decodePasskeyBytes(response.authenticatorData),
      rpId,
    );
    return passkeyCredential(
      response.rawId,
      response.clientExtensionResults,
      userHandle: response.userHandle,
    );
  }
}
