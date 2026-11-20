import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ndk_flutter/data_layer/data_sources/passkey_provider.dart';
import 'package:passkeys_platform_interface/passkeys_platform_interface.dart';
import 'package:passkeys_platform_interface/types/types.dart';

class _Authenticator extends PasskeysPlatform {
  RegisterRequestType? registration;
  AuthenticateRequestType? authentication;
  Map<String?, Object?>? extensions;
  String rawId = 'AQID';
  String userHandle = '';
  String? clientType;
  String? returnedChallenge;
  String? returnedRpId;
  int flags = 5;

  String clientData(String type, String challenge) => base64Url.encode(
    utf8.encode(
      jsonEncode({
        'type': clientType ?? type,
        'challenge': returnedChallenge ?? challenge,
        'origin': 'https://example.com',
      }),
    ),
  );

  @override
  Future<RegisterResponseType> register(RegisterRequestType request) async {
    registration = request;
    return RegisterResponseType(
      id: rawId,
      rawId: rawId,
      clientDataJSON: clientData('webauthn.create', request.challenge),
      attestationObject: '',
      transports: [],
      clientExtensionResults: extensions,
    );
  }

  @override
  Future<AuthenticateResponseType> authenticate(
    AuthenticateRequestType request,
  ) async {
    authentication = request;
    return AuthenticateResponseType(
      id: rawId,
      rawId: rawId,
      clientDataJSON: clientData('webauthn.get', request.challenge),
      authenticatorData: base64Url.encode([
        ...sha256
            .convert(utf8.encode(returnedRpId ?? request.relyingPartyId))
            .bytes,
        flags,
        0,
        0,
        0,
        0,
      ]),
      signature: '',
      userHandle: userHandle,
      clientExtensionResults: extensions,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final challenge = Uint8List.fromList(List.filled(32, 1));
  final salt = Uint8List.fromList(utf8.encode('nostr-pwk'));
  late _Authenticator authenticator;
  late PlatformPasskeyProvider provider;
  setUp(() {
    authenticator = _Authenticator();
    provider = PlatformPasskeyProvider(platform: authenticator);
  });

  test('uses the registered native platform by default', () async {
    final original = PasskeysPlatform.instance;
    PasskeysPlatform.instance = authenticator;
    try {
      final result = await PlatformPasskeyProvider().authenticate(
        rpId: 'example.com',
        challenge: challenge,
        prfInput: null,
      );
      expect(authenticator.authentication, isNotNull);
      expect(result.credentialId, [1, 2, 3]);
    } finally {
      PasskeysPlatform.instance = original;
    }
  });

  test('registers a discoverable passkey with PRF and required UV', () async {
    authenticator.extensions = {
      'prf': {'enabled': true},
    };
    final credential = await provider.register(
      rpId: 'example.com',
      rpName: 'Example',
      userName: 'Alice',
      challenge: challenge,
      userId: Uint8List.fromList([4, 5]),
      prfInput: salt,
    );
    final request = authenticator.registration!;
    expect(request.relyingParty.id, 'example.com');
    expect(request.user.id, 'BAU');
    expect(base64Url.decode(base64Url.normalize(request.challenge)), challenge);
    expect(base64Url.decode(base64Url.normalize(request.prf!)), salt);
    expect(request.authSelectionType!.residentKey, 'required');
    expect(request.authSelectionType!.userVerification, 'required');
    expect(request.authSelectionType!.authenticatorAttachment, isNull);
    expect(credential.prfEnabled, isTrue);
    expect(credential.credentialId, [1, 2, 3]);
    expect(credential.prfOutput, isNull);
  });

  test(
    'reads raw PRF extension results and constrains an explicit credential',
    () async {
      final expected = Uint8List.fromList(List.filled(32, 7));
      authenticator.extensions = {
        'prf': {
          'results': {'first': base64Url.encode(expected)},
        },
      };
      final credential = await provider.authenticate(
        rpId: 'example.com',
        challenge: challenge,
        prfInput: salt,
        credentialId: Uint8List.fromList([1, 2, 3]),
      );
      final request = authenticator.authentication!;
      expect(request.allowCredentials!.single.id, 'AQID');
      expect(request.userVerification, 'required');
      expect(request.canBeSecurityKey, isTrue);
      expect(request.preferImmediatelyAvailableCredentials, isFalse);
      expect(base64Url.decode(base64Url.normalize(request.prf!)), salt);
      expect(credential.prfOutput, expected);
    },
  );

  test('discovery omits PRF and preserves the assertion handle', () async {
    authenticator.userHandle = 'BAUG';
    final result = await provider.authenticate(
      rpId: 'example.com',
      challenge: challenge,
      prfInput: null,
    );
    expect(authenticator.authentication!.prf, isNull);
    expect(authenticator.authentication!.allowCredentials, isNull);
    expect(result.userHandle, [4, 5, 6]);
    expect(result.prfOutput, isNull);
    expect(result.prfEnabled, isNull);
  });

  test(
    'registration forwards exclusions and an explicitly disabled PRF',
    () async {
      authenticator.extensions = {
        'prf': {'enabled': false},
      };
      final result = await provider.register(
        rpId: 'example.com',
        rpName: 'Example',
        userName: 'Alice',
        challenge: challenge,
        userId: Uint8List.fromList([7]),
        prfInput: salt,
        excludeCredentialIds: [
          Uint8List.fromList([1, 2, 3]),
          Uint8List.fromList([4, 5, 6]),
        ],
      );
      expect(authenticator.registration!.excludeCredentials.map((e) => e.id), [
        'AQID',
        'BAUG',
      ]);
      expect(result.prfEnabled, isFalse);
      expect(result.userHandle, isNull);
    },
  );

  test('allows discoverable recovery without a local credential ID', () async {
    await provider.authenticate(
      rpId: 'example.com',
      challenge: challenge,
      prfInput: salt,
    );
    expect(authenticator.authentication!.allowCredentials, isNull);
  });

  test(
    'preserves the returned ID so the core can reject a different credential',
    () async {
      authenticator.rawId = 'BAUG';
      final result = await provider.authenticate(
        rpId: 'example.com',
        challenge: challenge,
        prfInput: salt,
        credentialId: Uint8List.fromList([1, 2, 3]),
      );
      expect(result.credentialId, [4, 5, 6]);
    },
  );

  test('rejects malformed or truncated PRF results', () async {
    for (final first in [
      42,
      'not base64!',
      base64Url.encode([1, 2]),
    ]) {
      authenticator.extensions = {
        'prf': {
          'results': {'first': first},
        },
      };
      await expectLater(
        provider.authenticate(
          rpId: 'example.com',
          challenge: challenge,
          prfInput: salt,
        ),
        throwsFormatException,
      );
    }
  });

  test('rejects a missing returned credential ID', () async {
    authenticator.rawId = '';
    await expectLater(
      provider.authenticate(
        rpId: 'example.com',
        challenge: challenge,
        prfInput: salt,
      ),
      throwsFormatException,
    );
  });
  test(
    'rejects wrong challenge, ceremony type, RP hash, and missing UV',
    () async {
      for (var scenario = 0; scenario < 4; scenario++) {
        authenticator = _Authenticator();
        provider = PlatformPasskeyProvider(platform: authenticator);
        if (scenario == 0) authenticator.returnedChallenge = 'AQID';
        if (scenario == 1) authenticator.clientType = 'webauthn.create';
        if (scenario == 2) authenticator.returnedRpId = 'other.example';
        if (scenario == 3) authenticator.flags = 1;
        await expectLater(
          provider.authenticate(
            rpId: 'example.com',
            challenge: challenge,
            prfInput: salt,
          ),
          throwsFormatException,
        );
      }
    },
  );

  test('checks the registration ceremony before returning its PRF', () async {
    authenticator.clientType = 'webauthn.get';
    await expectLater(
      provider.register(
        rpId: 'example.com',
        rpName: 'Example',
        userName: 'Alice',
        challenge: challenge,
        userId: Uint8List.fromList([4, 5]),
        prfInput: salt,
      ),
      throwsFormatException,
    );
  });
}
