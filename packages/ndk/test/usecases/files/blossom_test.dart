import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import 'package:ndk/data_layer/data_sources/http_request.dart';
import 'package:ndk/data_layer/repositories/blossom/blossom_impl.dart';
import 'package:ndk/data_layer/repositories/signers/bip340_event_signer.dart';
import 'package:ndk/domain_layer/usecases/files/blossom.dart';

import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

import '../../mocks/mock_blossom_server.dart';

void main() {
  late MockBlossomServer server;
  late Blossom client;

  setUp(() async {
    server = MockBlossomServer(port: 3000);
    await server.start();

    final blossomRepo = BlossomRepositoryImpl(
      client: HttpRequestDS(http.Client()),
    );

    KeyPair key1 = Bip340.generatePrivateKey();
    final signer = Bip340EventSigner(
        privateKey: key1.privateKey, publicKey: key1.publicKey);
    client = Blossom(blossomRepo, signer);
  });

  tearDown(() async {
    await server.stop();
  });

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
      expect(utf8.decode(getResponse), equals('Hello, Blossom!'));
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
      final deleteResponse = await client.delteBlob(
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
