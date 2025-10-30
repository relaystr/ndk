import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import 'package:ndk/data_layer/data_sources/http_request.dart';
import 'package:ndk/data_layer/repositories/blossom/blossom_impl.dart';
import 'package:ndk/domain_layer/repositories/blossom.dart';

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

  group("blossom upload strategy tests", () {
    test('Upload to first successful server only - firstSuccess', () async {
      final testData = Uint8List.fromList(utf8.encode('strategy test'));

      // Upload blob
      final uploadResponse = await client.uploadBlob(
        data: testData,
        serverUrls: [
          'http://dead.example.com',
          'http://localhost:3001',
          'http://localhost:3000',
        ],
        strategy: UploadStrategy.firstSuccess,
      );
      expect(uploadResponse.first.success, true);

      final sha256 = uploadResponse.first.descriptor!.sha256;

      final deadServer = client.getBlob(sha256: sha256, serverUrls: [
        'http://dead.example.com',
      ]);
      expect(deadServer, throwsException);

      final server1 = await client.getBlob(sha256: sha256, serverUrls: [
        'http://localhost:3001',
      ]);

      expect(utf8.decode(server1.data), equals('strategy test'));

      final server2 = client.getBlob(sha256: sha256, serverUrls: [
        'http://localhost:3000',
      ]);

      expect(server2, throwsException);
    });

    test('Upload to first successful server only - mirrorAfterSuccess',
        () async {
      final myData = "strategy test mirrorAfterSuccess";
      final testData = Uint8List.fromList(utf8.encode(myData));

      // Upload blob
      final uploadResponse = await client.uploadBlob(
        data: testData,
        serverUrls: [
          'http://dead.example.com',
          'http://localhost:3001',
          'http://localhost:3000',
        ],
        strategy: UploadStrategy.mirrorAfterSuccess,
      );
      expect(uploadResponse[0].success, false);
      expect(uploadResponse[1].success, true);
      expect(uploadResponse[2].success, true);

      final sha256 = uploadResponse[1].descriptor!.sha256;

      final deadServer = client.getBlob(sha256: sha256, serverUrls: [
        'http://dead.example.com',
      ]);
      expect(deadServer, throwsException);

      final server1 = await client.getBlob(sha256: sha256, serverUrls: [
        'http://localhost:3001',
      ]);

      expect(utf8.decode(server1.data), equals(myData));

      final server2 = await client.getBlob(sha256: sha256, serverUrls: [
        'http://localhost:3000',
      ]);

      expect(utf8.decode(server2.data), equals(myData));
    });

    test('Upload to first successful server only - allSimultaneous', () async {
      final myData = "strategy test allSimultaneous";
      final testData = Uint8List.fromList(utf8.encode(myData));

      // Upload blob
      final uploadResponse = await client.uploadBlob(
        data: testData,
        serverUrls: [
          'http://dead.example.com',
          'http://localhost:3001',
          'http://localhost:3000',
        ],
        strategy: UploadStrategy.allSimultaneous,
      );
      expect(uploadResponse[0].success, false);
      expect(uploadResponse[1].success, true);
      expect(uploadResponse[2].success, true);

      final sha256 = uploadResponse[1].descriptor!.sha256;

      final deadServer = client.getBlob(sha256: sha256, serverUrls: [
        'http://dead.example.com',
      ]);
      expect(deadServer, throwsException);

      final server1 = await client.getBlob(sha256: sha256, serverUrls: [
        'http://localhost:3001',
      ]);

      expect(utf8.decode(server1.data), equals(myData));

      final server2 = await client.getBlob(sha256: sha256, serverUrls: [
        'http://localhost:3000',
      ]);

      expect(utf8.decode(server2.data), equals(myData));
    });
  });

  group("stream blobs", () {
    final BlossomRepository blossomRepo = BlossomRepositoryImpl(
      client: HttpRequestDS(http.Client()),
    );
    test('getBlobStream should properly stream large files with range requests',
        () async {
      // First upload a test file to the mock server
      final testData = Uint8List.fromList(
          List.generate(5 * 1024 * 1024, (i) => i % 256)); // 5MB test file

      // Upload the test file
      final uploadResponse = await client.uploadBlob(
        data: testData,
        serverUrls: ['http://localhost:3000'],
      );

      expect(uploadResponse.first.success, true);
      final sha256 = uploadResponse.first.descriptor!.sha256;

      // Now test the streaming download
      final stream = await blossomRepo.getBlobStream(
        sha256: sha256,
        serverUrls: ['http://localhost:3000'],
        chunkSize: 1024 * 1024, // 1MB chunks
      );

      // Collect all chunks and verify the data
      final chunks = <Uint8List>[];
      int totalSize = 0;

      await for (final response in stream) {
        chunks.add(response.data);
        totalSize += response.data.length;

        // Verify chunk metadata
        expect(response.mimeType, isNotNull);
        expect(response.contentLength, equals(testData.length));
        //expect(response.contentRange, matches(RegExp(r'bytes \d+-\d+/\d+')));
      }

      // Combine chunks and verify the complete file
      final resultData = Uint8List(totalSize);
      int offset = 0;
      for (final chunk in chunks) {
        resultData.setRange(offset, offset + chunk.length, chunk);
        offset += chunk.length;
      }

      expect(resultData, equals(testData));
      expect(totalSize, equals(testData.length));
    });

    test(
        'getBlobStream should fallback to regular download if range requests not supported',
        () async {
      // Upload a smaller test file
      final testData = Uint8List.fromList(
          List.generate(1024, (i) => i % 256)); // 1KB test file

      final uploadResponse = await client.uploadBlob(
        data: testData,
        serverUrls: ['http://localhost:3000'],
      );

      expect(uploadResponse.first.success, true);
      final sha256 = uploadResponse.first.descriptor!.sha256;

      // Test the streaming download
      final stream = await blossomRepo.getBlobStream(
        sha256: sha256,
        serverUrls: ['http://localhost:3000'],
      );

      // Should receive exactly one chunk with the complete file
      final chunks = await stream.toList();
      expect(chunks.length, equals(1));
      expect(chunks.first.data, equals(testData));
    });

    test('getBlobStream should handle server errors gracefully', () async {
      expect(
        () => blossomRepo.getBlobStream(
          sha256: 'nonexistent_sha256',
          serverUrls: ['http://localhost:3000'],
        ),
        throwsException,
      );
    });

    test(
        'getBlobStream should try multiple servers until finding one that works',
        () async {
      final testData = Uint8List.fromList(
          List.generate(2 * 1024 * 1024, (i) => i % 256)); // 2MB test file

      final uploadResponse = await client.uploadBlob(
        data: testData,
        serverUrls: ['http://localhost:3000'],
      );

      final sha256 = uploadResponse.first.descriptor!.sha256;

      // Test with multiple servers, including non-existent ones
      final stream = await blossomRepo.getBlobStream(
        sha256: sha256,
        serverUrls: [
          'http://nonexistent-server:3000',
          'http://localhost:3000',
          'http://another-nonexistent:3000',
        ],
      );

      final receivedData = await stream
          .map((response) => response.data)
          .expand((chunk) => chunk)
          .toList();

      expect(Uint8List.fromList(receivedData), equals(testData));
    });

    test('getBlobStream with auth', () async {
      final testData = Uint8List.fromList(
          List.generate(2 * 1024 * 1024, (i) => i % 256)); // 2MB test file

      final uploadResponse = await client.uploadBlob(
        data: testData,
        serverUrls: ['http://localhost:3000'],
      );

      final sha256 = uploadResponse.first.descriptor!.sha256;

      // Test with multiple servers, including non-existent ones
      final stream = await client.getBlobStream(
        sha256: sha256,
        serverUrls: [
          'http://nonexistent-server:3000',
          'http://localhost:3000',
          'http://another-nonexistent:3000',
        ],
        useAuth: true,
        chunkSize: 1024,
      );

      final receivedData = await stream
          .map((response) => response.data)
          .expand((chunk) => chunk)
          .toList();

      expect(Uint8List.fromList(receivedData), equals(testData));
    });
  });

  group("report", () {
    test('report', () async {
      final reportRsp = await client.report(
          serverUrl: 'http://localhost:3000',
          sha256: "some_sha256",
          eventId: "some_event_id",
          reportMsg: "some_report_msg",
          reportType: "malware");

      expect(reportRsp, equals(200));
    });
  });

  test('Get blobs with NDK', () async {
    final ndk = Ndk.defaultConfig();

    final keyPair = Bip340.generatePrivateKey();
    ndk.accounts.loginPrivateKey(
      pubkey: keyPair.publicKey,
      privkey: keyPair.privateKey!,
    );

    await ndk.blossom.listBlobs(
      pubkey: ndk.accounts.getPublicKey()!,
      serverUrls: ["http://localhost:3000"],
    );
  });
}
