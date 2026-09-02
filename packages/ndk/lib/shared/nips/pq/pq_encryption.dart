import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../../../src/rust_lib.dart' as rust_lib;
import '../nip44/nip44.dart';

/// An ML-KEM-1024 keypair derived from a BIP-39 seed.
///
/// [secretKey] is long-term secret material. Treat it the way you would treat
/// the seed itself.
class PqKeyPair {
  final Uint8List publicKey;
  final Uint8List secretKey;

  const PqKeyPair({required this.publicKey, required this.secretKey});
}

/// Post-quantum hybrid encryption for Nostr direct messages.
///
/// Every encrypted message on Nostr today can be recorded now and decrypted
/// later, once a quantum computer breaks secp256k1 — NIP-44 derives its
/// conversation key from a secp256k1 ECDH secret. That is "harvest now,
/// decrypt later", and it is the only half of the quantum problem that can be
/// fixed *in advance*: a message protected today stays confidential
/// permanently. Forgery, by contrast, cannot be pre-empted — it is fixed only
/// by migrating signatures before the break.
///
/// The construction is **hybrid**: the ML-KEM-1024 shared secret is combined
/// with the ordinary NIP-44 conversation key through HKDF, so the result is
/// never weaker than what Nostr uses today. A break in a comparatively young
/// lattice scheme must not be able to make messaging *worse* than it is now.
///
/// The payload rides inside unchanged NIP-44 and NIP-59 gift wrap, so relays
/// need no changes and clients that have not implemented it are unaffected.
///
/// Wire-compatible with [`@nostr-wot/pq`](https://github.com/nostr-wot/nostr-wot-sdk/tree/main/packages/pq),
/// which is what the Nostr WoT browser extension ships. The Rust test suite
/// pins a complete envelope produced by that implementation.
///
/// ## What this does not do
///
/// It protects confidentiality only. Events are still signed with secp256k1,
/// so a quantum adversary can still forge events in your name.
class PqEncryption {
  PqEncryption._();

  /// Length of an ML-KEM-1024 encapsulation key, per FIPS 203.
  static const int kemPublicKeyBytes = 1568;

  /// A BIP-39 seed is always 64 bytes, whatever the mnemonic length.
  static const int seedBytes = 64;

  /// Derives the ML-KEM-1024 keypair for [account] from a BIP-39 [seed].
  ///
  /// The keys are siblings of the secp256k1 key derived from the same
  /// mnemonic, never children of it — an adversary who recovers the Nostr
  /// private key cannot repeat the derivation to reach these.
  ///
  /// [seed] must be the 64-byte BIP-39 seed, **not** a private key. Passing a
  /// 32-byte secp256k1 private key is rejected rather than silently producing
  /// unrelated keys.
  ///
  /// A 12-word mnemonic expands to a valid 64-byte seed carrying only 128 bits
  /// of entropy, which would make the seed — not the lattice — the weakest
  /// link. Callers advertising keys as seed-derived should require 24 words;
  /// this function cannot detect mnemonic length, because PBKDF2 stretches any
  /// mnemonic to 64 bytes.
  static PqKeyPair deriveKeyPair(Uint8List seed, {int account = 0}) {
    if (seed.length != seedBytes) {
      throw ArgumentError.value(
        seed.length,
        'seed',
        'expected a $seedBytes-byte BIP-39 seed',
      );
    }
    final seedPtr = calloc<Uint8>(seed.length);
    final pk = calloc<rust_lib.QsBuffer>();
    final sk = calloc<rust_lib.QsBuffer>();
    try {
      seedPtr.asTypedList(seed.length).setAll(0, seed);
      final ok = rust_lib.pqDeriveKemKeypair(
        seedPtr,
        seed.length,
        account,
        pk,
        sk,
      );
      if (ok != 1) throw StateError('Post-quantum key derivation failed');
      return PqKeyPair(publicKey: _copyOut(pk), secretKey: _copyOut(sk));
    } finally {
      // Wipe our copy of the seed before releasing it.
      seedPtr.asTypedList(seed.length).fillRange(0, seed.length, 0);
      calloc.free(seedPtr);
      calloc.free(pk);
      calloc.free(sk);
    }
  }

  /// Encrypts [plaintext] to [recipientKemKey], returning a base64 envelope.
  ///
  /// [recipientKemKey] comes from the recipient's published attestation.
  /// [senderPubkey] and [recipientPubkey] must be 64-character lowercase hex
  /// x-only pubkeys; they are bound into the AEAD so the ciphertext cannot be
  /// replayed into a different conversation or have its direction swapped.
  static Future<String> encrypt({
    required String plaintext,
    required Uint8List recipientKemKey,
    required String senderPrivateKey,
    required String senderPubkey,
    required String recipientPubkey,
  }) async {
    final conversationKey = _conversationKey(senderPrivateKey, recipientPubkey);
    final msg = Uint8List.fromList(utf8.encode(plaintext));

    final kemPtr = calloc<Uint8>(recipientKemKey.length);
    final convPtr = calloc<Uint8>(conversationKey.length);
    final msgPtr = calloc<Uint8>(msg.length);
    final out = calloc<rust_lib.QsBuffer>();
    final sender = senderPubkey.toNativeUtf8();
    final recipient = recipientPubkey.toNativeUtf8();
    try {
      kemPtr.asTypedList(recipientKemKey.length).setAll(0, recipientKemKey);
      convPtr.asTypedList(conversationKey.length).setAll(0, conversationKey);
      msgPtr.asTypedList(msg.length).setAll(0, msg);

      final ok = rust_lib.pqSeal(
        kemPtr,
        recipientKemKey.length,
        convPtr,
        conversationKey.length,
        sender,
        recipient,
        msgPtr,
        msg.length,
        out,
      );
      if (ok != 1) throw StateError('Post-quantum encryption failed');
      return utf8.decode(_copyOut(out));
    } finally {
      convPtr
          .asTypedList(conversationKey.length)
          .fillRange(0, conversationKey.length, 0);
      msgPtr.asTypedList(msg.length).fillRange(0, msg.length, 0);
      calloc.free(kemPtr);
      calloc.free(convPtr);
      calloc.free(msgPtr);
      calloc.free(out);
      calloc.free(sender);
      calloc.free(recipient);
    }
  }

  /// Decrypts a base64 envelope produced by [encrypt].
  ///
  /// Throws a single generic error on any failure. Distinguishing bad padding
  /// from a bad tag from a wrong key would hand an attacker an oracle.
  static Future<String> decrypt({
    required String payload,
    required Uint8List recipientKemSecretKey,
    required String recipientPrivateKey,
    required String senderPubkey,
    required String recipientPubkey,
  }) async {
    final conversationKey = _conversationKey(recipientPrivateKey, senderPubkey);

    final skPtr = calloc<Uint8>(recipientKemSecretKey.length);
    final convPtr = calloc<Uint8>(conversationKey.length);
    final out = calloc<rust_lib.QsBuffer>();
    final payloadPtr = payload.toNativeUtf8();
    final sender = senderPubkey.toNativeUtf8();
    final recipient = recipientPubkey.toNativeUtf8();
    try {
      skPtr
          .asTypedList(recipientKemSecretKey.length)
          .setAll(0, recipientKemSecretKey);
      convPtr.asTypedList(conversationKey.length).setAll(0, conversationKey);

      final ok = rust_lib.pqOpen(
        payloadPtr,
        skPtr,
        recipientKemSecretKey.length,
        convPtr,
        conversationKey.length,
        sender,
        recipient,
        out,
      );
      if (ok != 1) throw StateError('Decryption failed');
      return utf8.decode(_copyOut(out));
    } finally {
      skPtr
          .asTypedList(recipientKemSecretKey.length)
          .fillRange(0, recipientKemSecretKey.length, 0);
      convPtr
          .asTypedList(conversationKey.length)
          .fillRange(0, conversationKey.length, 0);
      calloc.free(skPtr);
      calloc.free(convPtr);
      calloc.free(out);
      calloc.free(payloadPtr);
      calloc.free(sender);
      calloc.free(recipient);
    }
  }

  /// Whether [payload] looks like a post-quantum envelope.
  ///
  /// A routing hint so a client can skip a decapsulation on ordinary NIP-17
  /// messages — not proof. Decryption is the only real check.
  static bool isPqEnvelope(String payload) {
    final ptr = payload.toNativeUtf8();
    try {
      return rust_lib.pqIsEnvelope(ptr) == 1;
    } finally {
      calloc.free(ptr);
    }
  }

  static Uint8List _conversationKey(String privateKey, String publicKey) {
    final shared = Nip44.computeSharedSecret(privateKey, publicKey);
    return Nip44.deriveConversationKey(shared);
  }

  /// Copies a Rust-owned buffer into Dart memory and frees the original.
  ///
  /// `qs_free_buffer` zeroizes before deallocating, so the Rust-side copy of
  /// any secret does not outlive this call.
  static Uint8List _copyOut(Pointer<rust_lib.QsBuffer> buf) {
    final b = buf.ref;
    final copy = Uint8List.fromList(b.data.asTypedList(b.len));
    rust_lib.qsFreeBuffer(b);
    return copy;
  }
}
