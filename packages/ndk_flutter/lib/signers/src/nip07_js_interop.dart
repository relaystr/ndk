import 'dart:js_interop';

@JS('window.nostr')
external Nostr? get nostr;

@JS()
@anonymous
extension type Nostr._(JSObject _) implements JSObject {
  external Nip04? get nip04;
  external Nip44? get nip44;
  external JSPromise<JSString> getPublicKey();
  external JSPromise<NostrEvent> signEvent(NostrEvent event);
}

@JS()
@anonymous
extension type Nip04._(JSObject _) implements JSObject {
  external JSPromise<JSString> encrypt(
    JSString recipientPubKey,
    JSString plaintext,
  );
  external JSPromise<JSString> decrypt(
    JSString senderPubKey,
    JSString ciphertext,
  );
}

@JS()
@anonymous
extension type Nip44._(JSObject _) implements JSObject {
  external JSPromise<JSString> encrypt(
    JSString recipientPubKey,
    JSString plaintext,
  );
  external JSPromise<JSString> decrypt(
    JSString senderPubKey,
    JSString ciphertext,
  );
}

@JS('Object')
extension type NostrEvent._(JSObject _) implements JSObject {
  external factory NostrEvent();

  external String? get id;
  external set id(String? value);

  external String? get sig;
  external set sig(String? value);

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

extension NostrEventExtension on NostrEvent {
  List<List<String>> get tagsList {
    final jsTags = tags.toDart;
    return jsTags.map((jsTag) {
      final tag = jsTag.toDart;
      return tag.map((item) => item.toDart).toList();
    }).toList();
  }
}
