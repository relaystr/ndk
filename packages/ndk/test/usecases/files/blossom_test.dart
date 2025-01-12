import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import 'package:ndk/data_layer/data_sources/http_request.dart';
import 'package:ndk/data_layer/repositories/blossom/blossom_impl.dart';
import 'package:ndk/domain_layer/usecases/files/blossom.dart';
import 'package:ndk/domain_layer/usecases/files/blossom_user_server_list.dart';
import 'package:ndk/ndk.dart';

import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

import '../../mocks/mock_blossom_server.dart';
import '../../mocks/mock_event_verifier.dart';

void main() {
  late MockBlossomServer server;
  late MockBlossomServer server2;
  late Blossom client;

  setUp(() async {
    server = MockBlossomServer(port: 3000);
    server2 = MockBlossomServer(port: 3001);
    await server.start();
    await server2.start();

    final blossomRepo = BlossomRepositoryImpl(
      client: HttpRequestDS(http.Client()),
    );

    KeyPair key1 = Bip340.generatePrivateKey();
    final signer = Bip340EventSigner(
        privateKey: key1.privateKey, publicKey: key1.publicKey);

    final ndk = Ndk(
      NdkConfig(
        eventVerifier: MockEventVerifier(),
        cache: MemCacheManager(),
        engine: NdkEngine.JIT,
      ),
    );

    final BlossomUserServerList blossomUserServerList =
        BlossomUserServerList(ndk.requests);
    client = Blossom(
      blossomImpl: blossomRepo,
      signer: signer,
      userServerList: blossomUserServerList,
    );
  });

  tearDown(() async {
    await server.stop();
    await server2.stop();
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
      expect(utf8.decode(getResponse.data), equals('Hello, Blossom!'));
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
