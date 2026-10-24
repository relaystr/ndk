@TestOn('browser')
library;

import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ndk_flutter/data_layer/data_sources/passkey_provider.dart';

void main() {
  final navigator = globalContext.getProperty<JSObject>('navigator'.toJS);
  final original = navigator.getProperty<JSObject>('credentials'.toJS);
  final challenge = Uint8List.fromList(List.filled(32, 1));
  final salt = Uint8List.fromList(utf8.encode('nostr-pwk'));
  final secret = Uint8List.fromList(List.filled(32, 7));
  final provider = PlatformPasskeyProvider();

  void replaceCredentials(JSObject credentials) {
    globalContext
        .getProperty<JSObject>('Object'.toJS)
        .callMethod<JSObject>(
          'defineProperty'.toJS,
          navigator,
          'credentials'.toJS,
          {'configurable': true, 'value': credentials}.jsify(),
        );
  }

  JSArrayBuffer buffer(List<int> bytes) =>
      Uint8List.fromList(bytes).toJS.getProperty<JSArrayBuffer>('buffer'.toJS);

  JSObject result(
    JSObject options,
    String type, {
    bool discovery = false,
    bool? enabled,
    List<int>? userHandle,
  }) {
    final pk = options.getProperty<JSObject>('publicKey'.toJS);
    expect(pk.getProperty<JSUint8Array>('challenge'.toJS).toDart, challenge);
    if (discovery) {
      expect(pk.hasProperty('extensions'.toJS).toDart, isFalse);
      expect(pk.hasProperty('allowCredentials'.toJS).toDart, isFalse);
    } else {
      final first = pk
          .getProperty<JSObject>('extensions'.toJS)
          .getProperty<JSObject>('prf'.toJS)
          .getProperty<JSObject>('eval'.toJS)
          .getProperty<JSUint8Array>('first'.toJS);
      expect(first.toDart, salt);
    }
    return {
          'rawId': buffer([1, 2, 3]),
          'response': {
            'userHandle': userHandle == null ? null : buffer(userHandle),
            'clientDataJSON': buffer(
              utf8.encode(
                jsonEncode({
                  'type': type,
                  'challenge': base64Url.encode(challenge).replaceAll('=', ''),
                  'origin': 'https://example.com',
                }),
              ),
            ),
            'authenticatorData': buffer([
              ...sha256.convert(utf8.encode('example.com')).bytes,
              5,
              0,
              0,
              0,
              0,
            ]),
          },
          'getClientExtensionResults':
              (() =>
                      {
                            'prf': {
                              if (enabled != null) 'enabled': enabled,
                              if (!discovery && enabled != false)
                                'results': {'first': buffer(secret)},
                            },
                          }.jsify()
                          as JSObject)
                  .toJS,
        }.jsify()
        as JSObject;
  }

  tearDown(() => replaceCredentials(original));

  test(
    'browser create/get preserve PRF buffers and credential selection',
    () async {
      var calls = 0;
      replaceCredentials(
        {
              'create': ((JSObject options) {
                calls++;
                final pk = options.getProperty<JSObject>('publicKey'.toJS);
                final selection = pk.getProperty<JSObject>(
                  'authenticatorSelection'.toJS,
                );
                expect(
                  selection.getProperty<JSString>('residentKey'.toJS).toDart,
                  'required',
                );
                expect(
                  selection
                      .getProperty<JSString>('userVerification'.toJS)
                      .toDart,
                  'required',
                );
                expect(
                  selection.hasProperty('authenticatorAttachment'.toJS).toDart,
                  isFalse,
                );
                final excluded = pk
                    .getProperty<JSArray<JSObject>>('excludeCredentials'.toJS)
                    .toDart;
                expect(
                  excluded.single.getProperty<JSUint8Array>('id'.toJS).toDart,
                  [9, 8],
                );
                return Future.value(result(options, 'webauthn.create')).toJS;
              }).toJS,
              'get': ((JSObject options) {
                calls++;
                final pk = options.getProperty<JSObject>('publicKey'.toJS);
                expect(
                  pk.getProperty<JSString>('userVerification'.toJS).toDart,
                  'required',
                );
                final allowed = pk
                    .getProperty<JSArray<JSObject>>('allowCredentials'.toJS)
                    .toDart;
                expect(
                  allowed.single.getProperty<JSUint8Array>('id'.toJS).toDart,
                  [1, 2, 3],
                );
                return Future.value(result(options, 'webauthn.get')).toJS;
              }).toJS,
            }.jsify()
            as JSObject,
      );
      final created = await provider.register(
        rpId: 'example.com',
        rpName: 'Example',
        userName: 'Alice',
        challenge: challenge,
        userId: Uint8List(32),
        excludeCredentialIds: [
          Uint8List.fromList([9, 8]),
        ],
        prfInput: salt,
      );
      expect(created.prfOutput, secret);
      final reopened = await provider.authenticate(
        rpId: 'example.com',
        challenge: challenge,
        prfInput: salt,
        credentialId: created.credentialId,
      );
      expect(reopened.prfOutput, secret);
      expect(calls, 2);
    },
  );

  test(
    'browser discovery preserves userHandle without requesting PRF',
    () async {
      replaceCredentials(
        {
              'get': ((JSObject options) => Future.value(
                result(
                  options,
                  'webauthn.get',
                  discovery: true,
                  userHandle: [4, 5, 6],
                ),
              ).toJS).toJS,
            }.jsify()
            as JSObject,
      );
      final credential = await provider.authenticate(
        rpId: 'example.com',
        challenge: challenge,
        prfInput: null,
      );
      expect(credential.userHandle, [4, 5, 6]);
      expect(credential.prfOutput, isNull);
      expect(credential.prfEnabled, isNull);
    },
  );

  test('browser preserves explicitly disabled registration PRF', () async {
    replaceCredentials(
      {
            'create': ((JSObject options) => Future.value(
              result(options, 'webauthn.create', enabled: false),
            ).toJS).toJS,
          }.jsify()
          as JSObject,
    );
    final credential = await provider.register(
      rpId: 'example.com',
      rpName: 'Example',
      userName: 'Alice',
      challenge: challenge,
      userId: Uint8List(32),
      prfInput: salt,
    );
    expect(credential.prfEnabled, isFalse);
    expect(credential.prfOutput, isNull);
    expect(credential.userHandle, isNull);
  });

  test(
    'browser cancellation propagates without creating a credential',
    () async {
      var calls = 0;
      var creations = 0;
      replaceCredentials(
        {
              'get': ((JSObject options) {
                calls++;
                return Future<JSObject>.error(StateError('cancelled')).toJS;
              }).toJS,
              'create': ((JSObject options) {
                creations++;
                return Future<JSObject>.error(
                  StateError('unexpected creation'),
                ).toJS;
              }).toJS,
            }.jsify()
            as JSObject,
      );
      await expectLater(
        provider.authenticate(
          rpId: 'example.com',
          challenge: challenge,
          prfInput: salt,
        ),
        throwsA(anything),
      );
      expect(calls, 1);
      expect(creations, 0);
    },
  );
}
