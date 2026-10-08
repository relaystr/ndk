@TestOn('browser')
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:ndk_flutter/signers/web_event_signer.dart';
import 'package:ndk_flutter/verifiers/web_event_verifier.dart';

void _report(String label, int count, int ms) {
  final perOp = count > 0 ? (ms / count).toStringAsFixed(2) : '0';
  if (kDebugMode) {
    print('[$label] $count ops in ${ms}ms ($perOp ms/op)');
  }
}

void main() {
  group('WebEventSigner benchmark', () {
    late KeyPair keyPair;
    late Nip01Event event;

    setUpAll(() {
      keyPair = Bip340.generatePrivateKey();
      event = Nip01Event(
        pubKey: keyPair.publicKey,
        kind: 1,
        tags: [],
        content: 'Benchmark event content',
      );
    });

    test('benchmark sign', () async {
      const count = 10;

      final webSigner = WebEventSigner(
        privateKey: keyPair.privateKey,
        publicKey: keyPair.publicKey,
      );
      final dartSigner = Bip340EventSigner(
        privateKey: keyPair.privateKey,
        publicKey: keyPair.publicKey,
      );

      // Warmup
      for (var i = 0; i < 3; i++) {
        await webSigner.sign(event);
      }
      for (var i = 0; i < 3; i++) {
        await dartSigner.sign(event);
      }

      // Web
      var sw = Stopwatch()..start();
      for (var i = 0; i < count; i++) {
        await webSigner.sign(event);
      }
      sw.stop();
      _report('WebEventSigner.sign', count, sw.elapsedMilliseconds);

      // Dart
      sw = Stopwatch()..start();
      for (var i = 0; i < count; i++) {
        await dartSigner.sign(event);
      }
      sw.stop();
      _report('Bip340EventSigner.sign', count, sw.elapsedMilliseconds);

      await webSigner.dispose();
      await dartSigner.dispose();
    });

    test('benchmark verify', () async {
      const count = 50;

      final signer = Bip340EventSigner(
        privateKey: keyPair.privateKey,
        publicKey: keyPair.publicKey,
      );
      final signedEvent = await signer.sign(event);
      await signer.dispose();

      final webVerifier = WebEventVerifier();
      final dartVerifier = Bip340EventVerifier();

      // Warmup
      for (var i = 0; i < 3; i++) {
        await webVerifier.verify(signedEvent);
      }
      for (var i = 0; i < 3; i++) {
        await dartVerifier.verify(signedEvent);
      }

      // Web
      var sw = Stopwatch()..start();
      for (var i = 0; i < count; i++) {
        await webVerifier.verify(signedEvent);
      }
      sw.stop();
      _report('WebEventVerifier.verify', count, sw.elapsedMilliseconds);

      // Dart
      sw = Stopwatch()..start();
      for (var i = 0; i < count; i++) {
        await dartVerifier.verify(signedEvent);
      }
      sw.stop();
      _report('Bip340EventVerifier.verify', count, sw.elapsedMilliseconds);
    });

    test('benchmark nip04 encrypt', () async {
      const count = 10;
      const message = 'Hello, NIP-04 benchmark!';
      final otherKeyPair = Bip340.generatePrivateKey();

      final webSigner = WebEventSigner(
        privateKey: keyPair.privateKey,
        publicKey: keyPair.publicKey,
      );
      final dartSigner = Bip340EventSigner(
        privateKey: keyPair.privateKey,
        publicKey: keyPair.publicKey,
      );

      // Warmup
      for (var i = 0; i < 3; i++) {
        await webSigner.encrypt(message, otherKeyPair.publicKey);
      }
      for (var i = 0; i < 3; i++) {
        await dartSigner.encrypt(message, otherKeyPair.publicKey);
      }

      // Web
      var sw = Stopwatch()..start();
      for (var i = 0; i < count; i++) {
        await webSigner.encrypt(message, otherKeyPair.publicKey);
      }
      sw.stop();
      _report('WebEventSigner.nip04Encrypt', count, sw.elapsedMilliseconds);

      // Dart
      sw = Stopwatch()..start();
      for (var i = 0; i < count; i++) {
        await dartSigner.encrypt(message, otherKeyPair.publicKey);
      }
      sw.stop();
      _report('Bip340EventSigner.nip04Encrypt', count, sw.elapsedMilliseconds);

      await webSigner.dispose();
      await dartSigner.dispose();
    });

    test('benchmark nip44 encrypt', () async {
      const count = 10;
      const message = 'Hello, NIP-44 benchmark!';
      final otherKeyPair = Bip340.generatePrivateKey();

      final webSigner = WebEventSigner(
        privateKey: keyPair.privateKey,
        publicKey: keyPair.publicKey,
      );
      final dartSigner = Bip340EventSigner(
        privateKey: keyPair.privateKey,
        publicKey: keyPair.publicKey,
      );

      // Warmup
      for (var i = 0; i < 3; i++) {
        await webSigner.encryptNip44(
          plaintext: message,
          recipientPubKey: otherKeyPair.publicKey,
        );
      }
      for (var i = 0; i < 3; i++) {
        await dartSigner.encryptNip44(
          plaintext: message,
          recipientPubKey: otherKeyPair.publicKey,
        );
      }

      // Web
      var sw = Stopwatch()..start();
      for (var i = 0; i < count; i++) {
        await webSigner.encryptNip44(
          plaintext: message,
          recipientPubKey: otherKeyPair.publicKey,
        );
      }
      sw.stop();
      _report('WebEventSigner.nip44Encrypt', count, sw.elapsedMilliseconds);

      // Dart
      sw = Stopwatch()..start();
      for (var i = 0; i < count; i++) {
        await dartSigner.encryptNip44(
          plaintext: message,
          recipientPubKey: otherKeyPair.publicKey,
        );
      }
      sw.stop();
      _report('Bip340EventSigner.nip44Encrypt', count, sw.elapsedMilliseconds);

      await webSigner.dispose();
      await dartSigner.dispose();
    });

    test('benchmark nip04 decrypt', () async {
      const count = 10;
      const message = 'Hello, NIP-04 decrypt benchmark!';
      final otherKeyPair = Bip340.generatePrivateKey();

      final webSigner = WebEventSigner(
        privateKey: keyPair.privateKey,
        publicKey: keyPair.publicKey,
      );
      final dartSigner = Bip340EventSigner(
        privateKey: otherKeyPair.privateKey,
        publicKey: otherKeyPair.publicKey,
      );

      final encrypted = await webSigner.encrypt(
        message,
        otherKeyPair.publicKey,
      );
      if (encrypted == null) throw Exception('Encrypt failed');

      // Warmup
      for (var i = 0; i < 3; i++) {
        await dartSigner.decrypt(encrypted, keyPair.publicKey);
      }
      for (var i = 0; i < 3; i++) {
        await webSigner.decrypt(encrypted, otherKeyPair.publicKey);
      }

      // Dart decrypt
      var sw = Stopwatch()..start();
      for (var i = 0; i < count; i++) {
        await dartSigner.decrypt(encrypted, keyPair.publicKey);
      }
      sw.stop();
      _report('Bip340EventSigner.nip04Decrypt', count, sw.elapsedMilliseconds);

      // Web decrypt
      sw = Stopwatch()..start();
      for (var i = 0; i < count; i++) {
        await webSigner.decrypt(encrypted, otherKeyPair.publicKey);
      }
      sw.stop();
      _report('WebEventSigner.nip04Decrypt', count, sw.elapsedMilliseconds);

      await webSigner.dispose();
      await dartSigner.dispose();
    });

    test('benchmark nip44 decrypt', () async {
      const count = 10;
      const message = 'Hello, NIP-44 decrypt benchmark!';
      final otherKeyPair = Bip340.generatePrivateKey();

      final webSigner = WebEventSigner(
        privateKey: keyPair.privateKey,
        publicKey: keyPair.publicKey,
      );
      final dartSigner = Bip340EventSigner(
        privateKey: otherKeyPair.privateKey,
        publicKey: otherKeyPair.publicKey,
      );

      final encrypted = await webSigner.encryptNip44(
        plaintext: message,
        recipientPubKey: otherKeyPair.publicKey,
      );
      if (encrypted == null) throw Exception('Encrypt failed');

      // Warmup
      for (var i = 0; i < 3; i++) {
        await dartSigner.decryptNip44(
          ciphertext: encrypted,
          senderPubKey: keyPair.publicKey,
        );
      }
      for (var i = 0; i < 3; i++) {
        await webSigner.decryptNip44(
          ciphertext: encrypted,
          senderPubKey: otherKeyPair.publicKey,
        );
      }

      // Dart decrypt
      var sw = Stopwatch()..start();
      for (var i = 0; i < count; i++) {
        await dartSigner.decryptNip44(
          ciphertext: encrypted,
          senderPubKey: keyPair.publicKey,
        );
      }
      sw.stop();
      _report('Bip340EventSigner.nip44Decrypt', count, sw.elapsedMilliseconds);

      // Web decrypt
      sw = Stopwatch()..start();
      for (var i = 0; i < count; i++) {
        await webSigner.decryptNip44(
          ciphertext: encrypted,
          senderPubKey: otherKeyPair.publicKey,
        );
      }
      sw.stop();
      _report('WebEventSigner.nip44Decrypt', count, sw.elapsedMilliseconds);

      await webSigner.dispose();
      await dartSigner.dispose();
    });
  });
}
