import 'dart:js_interop';
import 'package:ndk/ndk.dart';
import 'js_interop.dart' as js;

class Nip07EventSigner implements EventSigner {
  String? cachedPublicKey;

  Nip07EventSigner({this.cachedPublicKey});

  @override
  bool canSign() {
    return js.nostr != null;
  }

  @override
  Future<String?> decrypt(String msg, String destPubKey,
      {String? id, Duration? timeout}) async {
    // timeout is ignored for local signer
    if (js.nostr == null) {
      throw Exception('NIP-07 extension not available');
    }

    final result = await js.nostr!.nip04!
        .decrypt(destPubKey.toJS, msg.toJS)
        .toDart;

    return result.toDart;
  }

  @override
  Future<String?> decryptNip44({
    required String ciphertext,
    required String senderPubKey,
    Duration? timeout,
  }) async {
    // timeout is ignored for local signer
    if (js.nostr == null) {
      throw Exception('NIP-07 extension not available');
    }

    final result = await js.nostr!.nip44!
        .decrypt(senderPubKey.toJS, ciphertext.toJS)
        .toDart;

    return result.toDart;
  }

  @override
  Future<String?> encrypt(String msg, String destPubKey,
      {String? id, Duration? timeout}) async {
    // timeout is ignored for local signer
    if (js.nostr == null) {
      throw Exception('NIP-07 extension not available');
    }

    final result = await js.nostr!.nip04!
        .encrypt(destPubKey.toJS, msg.toJS)
        .toDart;

    return result.toDart;
  }

  @override
  Future<String?> encryptNip44({
    required String plaintext,
    required String recipientPubKey,
    Duration? timeout,
  }) async {
    // timeout is ignored for local signer
    if (js.nostr == null) {
      throw Exception('NIP-07 extension not available');
    }

    final result = await js.nostr!.nip44!
        .encrypt(recipientPubKey.toJS, plaintext.toJS)
        .toDart;

    return result.toDart;
  }

  @override
  String getPublicKey() {
    if (cachedPublicKey != null) return cachedPublicKey!;

    js.nostr!.getPublicKey().toDart.then((pubkey) {
      cachedPublicKey = pubkey.toDart;
    });

    throw Exception("Use getPublicKeyAsync with Nip07EventSigner");
  }

  Future<String> getPublicKeyAsync() async {
    final pubkey = (await js.nostr!.getPublicKey().toDart).toDart;
    cachedPublicKey = pubkey;

    return pubkey;
  }

  @override
  Future<Nip01Event> sign(Nip01Event event, {Duration? timeout}) async {
    // timeout is ignored for local signer
    if (js.nostr == null) {
      throw Exception('NIP-07 extension not available');
    }

    final jsEvent = js.NostrEvent()
      ..pubkey = event.pubKey
      ..created_at = event.createdAt
      ..kind = event.kind
      ..content = event.content
      ..tags = event.tags
          .map((tag) => tag.map((item) => item.toJS).toList().toJS)
          .toList()
          .toJS;

    // Sign the event using NIP-07
    final signedEvent = await js.nostr!.signEvent(jsEvent).toDart;

    return event.copyWith(id: signedEvent.id!, sig: signedEvent.sig!);
  }
}
