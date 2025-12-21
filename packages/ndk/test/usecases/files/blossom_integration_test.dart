import 'dart:convert';
import 'dart:typed_data';

import 'package:ndk/ndk.dart';

import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

import '../../mocks/mock_event_verifier.dart';

void main() {
  late Blossom client;

  setUp(() async {
    KeyPair key1 = Bip340.generatePrivateKey();

    final ndk = Ndk(
      NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: MemCacheManager(),
        engine: NdkEngine.JIT,
      ),
    );
    ndk.accounts
        .loginPrivateKey(pubkey: key1.publicKey, privkey: key1.privateKey!);

    client = ndk.blossom;
  });

  tearDown(() async {});

  group('Blossom Client Integration Tests', () {
    test('Upload and retrieve blob', () async {
      final testData = Uint8List.fromList(utf8.encode('Hello, Blossom!'));

      // Upload blob
      final uploadResponse = await client.uploadBlob(
        data: testData,
        serverUrls: ['http://localhost:3000'],
      );
      expect(uploadResponse.first.success, true);

      final sha256 = uploadResponse.first.descriptor!.sha256;

      // Retrieve blob
      final getResponse = await client.getBlob(
        sha256: sha256,
        serverUrls: ['http://localhost:3000'],
      );

      final getResponseAuth = await client.getBlob(
        sha256: sha256,
        serverUrls: ['http://localhost:3000'],
        useAuth: true,
      );
      expect(utf8.decode(getResponse.data), equals('Hello, Blossom!'));
      expect(utf8.decode(getResponseAuth.data), equals('Hello, Blossom!'));
    });

    test('Upload and check blob', () async {
      final testData = Uint8List.fromList(utf8.encode('Hello, Blossom!'));

      // Upload blob
      final uploadResponse = await client.uploadBlob(
        data: testData,
        serverUrls: ['http://localhost:3000'],
      );
      expect(uploadResponse.first.success, true);

      final sha256 = uploadResponse.first.descriptor!.sha256;

      // Retrieve blob
      final getResponse = client.checkBlob(
        sha256: sha256,
        serverUrls: ['http://localhost:3000'],
      );
      final getResponseAuth = client.checkBlob(
        sha256: sha256,
        serverUrls: ['http://localhost:3000'],
        useAuth: true,
      );

      /// expect not to throw

      expect(getResponse, completion('http://localhost:3000/$sha256'));
      expect(getResponseAuth, completion('http://localhost:3000/$sha256'));

      final getResponseVoid = client.checkBlob(
        sha256: "nonexistent_sha256",
        serverUrls: ['http://localhost:3000'],
      );

      expect(getResponseVoid, throwsException);
    });

    test('Upload and retrieve blob - one out of three', () async {
      final testData = Uint8List.fromList(utf8.encode('Hello World!'));

      // Upload blob
      final uploadResponse = await client.uploadBlob(
        data: testData,
        serverUrls: ['http://localhost:3000'],
      );
      expect(uploadResponse.first.success, true);

      final sha256 = uploadResponse.first.descriptor!.sha256;

      // Retrieve blob
      final getResponse = await client.getBlob(
        sha256: sha256,
        serverUrls: [
          'http://dead.example.com',
          'http://localhost:3001',
          'http://localhost:3000',
        ],
      );
      expect(utf8.decode(getResponse.data), equals('Hello World!'));
    });

    test('List blobs for user', () async {
      // Upload some test blobs first
      final testData1 = Uint8List.fromList(utf8.encode('Test 1'));
      final testData2 = Uint8List.fromList(utf8.encode('Test 2'));

      await client.uploadBlob(
        data: testData1,
        serverUrls: ['http://localhost:3000'],
      );
      await client.uploadBlob(
        data: testData2,
        serverUrls: ['http://localhost:3000'],
      );

      final listResponse = await client.listBlobs(
        pubkey: 'test_pubkey',
        serverUrls: ['http://localhost:3000'],
      );

      expect(listResponse.length, equals(2));
    });

    test('Delete blob', () async {
      final testData = Uint8List.fromList(utf8.encode('Hello, Blossom!'));

      // Upload blob
      final uploadResponse = await client.uploadBlob(
        data: testData,
        serverUrls: ['http://localhost:3000'],
      );
      expect(uploadResponse.first.success, true);

      final sha256 = uploadResponse.first.descriptor!.sha256;

      // Delete blob
      final deleteResponse = await client.deleteBlob(
        sha256: sha256,
        serverUrls: ['http://localhost:3000'],
      );
      expect(deleteResponse.first.success, true);

      // Retrieve blob
      final getResponse = client.getBlob(
        sha256: sha256,
        serverUrls: ['http://localhost:3000'],
      );
      //check that something throws an error
      expect(getResponse, throwsException);
    });
  });
}
