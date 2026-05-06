import 'dart:js_interop';

@JS('NostrCrypto')
external NostrCrypto? get nostrCrypto;

@JS()
@anonymous
extension type NostrCrypto._(JSObject _) implements JSObject {
  external JSPromise<JSBoolean> verifyEvent(NostrEventJS event);
  external JSPromise<JSBoolean> verifySignature(
    JSString signatureHex,
    JSString messageHash,
    JSString publicKeyHex,
  );
  external JSPromise<JSString> signEvent(
    JSString privateKeyHex,
    JSString messageHashHex,
  );
  external JSPromise<JSString> nip04Encrypt(
    JSString privateKeyHex,
    JSString publicKeyHex,
    JSString plaintext,
  );
  external JSPromise<JSString> nip04Decrypt(
    JSString privateKeyHex,
    JSString publicKeyHex,
    JSString ciphertext,
  );
  external JSPromise<JSString> nip44Encrypt(
    JSString privateKeyHex,
    JSString publicKeyHex,
    JSString plaintext,
  );
  external JSPromise<JSString> nip44Decrypt(
    JSString privateKeyHex,
    JSString publicKeyHex,
    JSString payloadB64,
  );
}

@JS('Object')
extension type NostrEventJS._(JSObject _) implements JSObject {
  external factory NostrEventJS();

  external String get id;
  external set id(String value);

  external String get sig;
  external set sig(String value);

  external String get pubkey;
  external set pubkey(String value);

  // ignore: non_constant_identifier_names
  external int get created_at;
  // ignore: non_constant_identifier_names
  external set created_at(int value);

  external int get kind;
  external set kind(int value);

  external JSArray<JSArray<JSString>> get tags;
  external set tags(JSArray<JSArray<JSString>> value);

  external String get content;
  external set content(String value);
}
