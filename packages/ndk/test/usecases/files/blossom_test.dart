import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import 'package:ndk/data_layer/data_sources/http_request.dart';
import 'package:ndk/data_layer/io/file_io_platform.dart';
import 'package:ndk/data_layer/repositories/blossom/blossom_impl.dart';
import 'package:ndk/domain_layer/entities/blob_upload_progress.dart';
import 'package:ndk/domain_layer/repositories/blossom.dart';

import 'package:ndk/ndk.dart';

import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

import '../../mocks/mock_blossom_server.dart';
import '../../mocks/mock_event_verifier.dart';

const int primaryServerPort = 30000;
const int secondaryServerPort = 30001;

void main() {
  late MockBlossomServer server;
  late MockBlossomServer server2;
  late Blossom client;

  setUp(() async {
    server = MockBlossomServer(port: primaryServerPort);
    server2 = MockBlossomServer(port: secondaryServerPort);
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
        serverUrls: ['http://localhost:${server.port}'],
      );
      expect(uploadResponse.first.success, true);

      final sha256 = uploadResponse.first.descriptor!.sha256;

      // Retrieve blob
      final getResponse = await client.getBlob(
        sha256: sha256,
        serverUrls: ['http://localhost:${server.port}'],
      );

      final getResponseAuth = await client.getBlob(
        sha256: sha256,
        serverUrls: ['http://localhost:${server.port}'],
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
        serverUrls: ['http://localhost:${server.port}'],
      );
      expect(uploadResponse.first.success, true);

      final sha256 = uploadResponse.first.descriptor!.sha256;

      // Retrieve blob
      final getResponse = client.checkBlob(
        sha256: sha256,
        serverUrls: ['http://localhost:${server.port}'],
      );
      final getResponseAuth = client.checkBlob(
        sha256: sha256,
        serverUrls: ['http://localhost:${server.port}'],
        useAuth: true,
      );

      /// expect not to throw

      expect(
          getResponse, completion('http://localhost:${server.port}/$sha256'));
      expect(getResponseAuth,
          completion('http://localhost:${server.port}/$sha256'));

      final getResponseVoid = client.checkBlob(
        sha256: "nonexistent_sha256",
        serverUrls: ['http://localhost:${server.port}'],
      );

      expect(getResponseVoid, throwsException);
    });

    test('Upload and retrieve blob - one out of three', () async {
      final testData = Uint8List.fromList(utf8.encode('Hello World!'));

      // Upload blob
      final uploadResponse = await client.uploadBlob(
        data: testData,
        serverUrls: ['http://localhost:${server.port}'],
      );
      expect(uploadResponse.first.success, true);

      final sha256 = uploadResponse.first.descriptor!.sha256;

      // Retrieve blob
      final getResponse = await client.getBlob(
        sha256: sha256,
        serverUrls: [
          'http://dead.example.com',
          'http://localhost:${server2.port}',
          'http://localhost:${server.port}',
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
        serverUrls: ['http://localhost:${server.port}'],
      );
      await client.uploadBlob(
        data: testData2,
        serverUrls: ['http://localhost:${server.port}'],
      );

      final listResponse = await client.listBlobs(
        pubkey: 'test_pubkey',
        serverUrls: ['http://localhost:${server.port}'],
      );

      expect(listResponse.length, equals(2));
    });

    test('Delete blob', () async {
      final testData = Uint8List.fromList(utf8.encode('Hello, Blossom!'));

      // Upload blob
      final uploadResponse = await client.uploadBlob(
        data: testData,
        serverUrls: ['http://localhost:${server.port}'],
      );
      expect(uploadResponse.first.success, true);

      final sha256 = uploadResponse.first.descriptor!.sha256;

      // Delete blob
      final deleteResponse = await client.deleteBlob(
        sha256: sha256,
        serverUrls: ['http://localhost:${server.port}'],
      );
      expect(deleteResponse.first.success, true);

      // Retrieve blob
      final getResponse = client.getBlob(
        sha256: sha256,
        serverUrls: ['http://localhost:${server.port}'],
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
          'http://localhost:${server2.port}',
          'http://localhost:${server.port}',
        ],
        strategy: UploadStrategy.firstSuccess,
      );
      // Assert results by server URL instead of relying on order
      final dead = uploadResponse
          .firstWhere((r) => r.serverUrl == 'http://dead.example.com');
      final server1Result = uploadResponse.firstWhere(
          (r) => r.serverUrl == 'http://localhost:$secondaryServerPort');

      expect(dead.success, false);
      expect(server1Result.success, true);

      final sha256 = server1Result.descriptor!.sha256;

      final deadServer = client.getBlob(sha256: sha256, serverUrls: [
        'http://dead.example.com',
      ]);
      expect(deadServer, throwsException);

      final server1 = await client.getBlob(sha256: sha256, serverUrls: [
        'http://localhost:${server2.port}',
      ]);

      expect(utf8.decode(server1.data), equals('strategy test'));

      final served2 = client.getBlob(sha256: sha256, serverUrls: [
        'http://localhost:${server.port}',
      ]);

      expect(served2, throwsException);
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
          'http://localhost:${server2.port}',
          'http://localhost:${server.port}',
        ],
        strategy: UploadStrategy.mirrorAfterSuccess,
      );
      // Assert results by server URL instead of relying on order
      final dead = uploadResponse
          .firstWhere((r) => r.serverUrl == 'http://dead.example.com');
      final server1Result = uploadResponse.firstWhere(
          (r) => r.serverUrl == 'http://localhost:$secondaryServerPort');
      final server2Result = uploadResponse.firstWhere(
          (r) => r.serverUrl == 'http://localhost:$primaryServerPort');

      expect(dead.success, false);
      expect(server1Result.success, true);
      expect(server2Result.success, true);

      final sha256 = server1Result.descriptor!.sha256;

      final deadServer = client.getBlob(sha256: sha256, serverUrls: [
        'http://dead.example.com',
      ]);
      expect(deadServer, throwsException);

      final server1 = await client.getBlob(sha256: sha256, serverUrls: [
        'http://localhost:${server2.port}',
      ]);

      expect(utf8.decode(server1.data), equals(myData));

      final served2 = await client.getBlob(sha256: sha256, serverUrls: [
        'http://localhost:${server.port}',
      ]);

      expect(utf8.decode(served2.data), equals(myData));
    });

    test('Upload to first successful server only - allSimultaneous', () async {
      final myData = "strategy test allSimultaneous";
      final testData = Uint8List.fromList(utf8.encode(myData));

      // Upload blob
      final uploadResponse = await client.uploadBlob(
        data: testData,
        serverUrls: [
          'http://dead.example.com',
          'http://localhost:${server2.port}',
          'http://localhost:${server.port}',
        ],
        strategy: UploadStrategy.allSimultaneous,
      );
      // Assert results by server URL instead of relying on order
      final dead = uploadResponse
          .firstWhere((r) => r.serverUrl == 'http://dead.example.com');
      final server1Result = uploadResponse.firstWhere(
          (r) => r.serverUrl == 'http://localhost:$secondaryServerPort');
      final server2Result = uploadResponse.firstWhere(
          (r) => r.serverUrl == 'http://localhost:$primaryServerPort');

      expect(dead.success, false);
      expect(server1Result.success, true);
      expect(server2Result.success, true);

      final sha256 = server1Result.descriptor!.sha256;

      final deadServer = client.getBlob(sha256: sha256, serverUrls: [
        'http://dead.example.com',
      ]);
      expect(deadServer, throwsException);

      final server1 = await client.getBlob(sha256: sha256, serverUrls: [
        'http://localhost:${server2.port}',
      ]);

      expect(utf8.decode(server1.data), equals(myData));

      final served2 = await client.getBlob(sha256: sha256, serverUrls: [
        'http://localhost:${server.port}',
      ]);

      expect(utf8.decode(served2.data), equals(myData));
    });
  });

  group("stream blobs", () {
    final BlossomRepository blossomRepo = BlossomRepositoryImpl(
      client: HttpRequestDS(http.Client()),
      fileIO: createFileIO(),
    );
    test('getBlobStream should properly stream large files with range requests',
        () async {
      // First upload a test file to the mock server
      final testData = Uint8List.fromList(
          List.generate(5 * 1024 * 1024, (i) => i % 256)); // 5MB test file

      // Upload the test file
      final uploadResponse = await client.uploadBlob(
        data: testData,
        serverUrls: ['http://localhost:${server.port}'],
      );

      expect(uploadResponse.first.success, true);
      final sha256 = uploadResponse.first.descriptor!.sha256;

      // Now test the streaming download
      final stream = await blossomRepo.getBlobStream(
        sha256: sha256,
        serverUrls: ['http://localhost:${server.port}'],
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
        serverUrls: ['http://localhost:${server.port}'],
      );

      expect(uploadResponse.first.success, true);
      final sha256 = uploadResponse.first.descriptor!.sha256;

      // Test the streaming download
      final stream = await blossomRepo.getBlobStream(
        sha256: sha256,
        serverUrls: ['http://localhost:${server.port}'],
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
          serverUrls: ['http://localhost:${server.port}'],
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
        serverUrls: ['http://localhost:${server.port}'],
      );

      final sha256 = uploadResponse.first.descriptor!.sha256;

      // Test with multiple servers, including non-existent ones
      final stream = await blossomRepo.getBlobStream(
        sha256: sha256,
        serverUrls: [
          'http://nonexistent-server:${server.port}',
          'http://localhost:${server.port}',
          'http://another-nonexistent:${server.port}',
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
        serverUrls: ['http://localhost:${server.port}'],
      );

      final sha256 = uploadResponse.first.descriptor!.sha256;

      // Test with multiple servers, including non-existent ones
      final stream = await client.getBlobStream(
        sha256: sha256,
        serverUrls: [
          'http://nonexistent-server:${server.port}',
          'http://localhost:${server.port}',
          'http://another-nonexistent:${server.port}',
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

  group("mirror", () {
    test('mirrorToServers should mirror blob from one server to others',
        () async {
      final myData = "mirror test data";
      final testData = Uint8List.fromList(utf8.encode(myData));

      // Upload blob to first server only
      final uploadResponse = await client.uploadBlob(
        data: testData,
        serverUrls: ['http://localhost:$primaryServerPort'],
      );
      expect(uploadResponse.first.success, true);

      final sha256 = uploadResponse.first.descriptor!.sha256;
      final blossomUrl =
          Uri.parse('http://localhost:$primaryServerPort/$sha256');

      // Mirror to the second server
      final mirrorResponse = await client.mirrorToServers(
        blossomUrl: blossomUrl,
        targetServerUrls: ['http://localhost:$secondaryServerPort'],
      );

      expect(mirrorResponse.length, equals(1));
      expect(mirrorResponse.first.success, true);
      expect(mirrorResponse.first.descriptor?.sha256, equals(sha256));

      // Verify both servers now have the blob
      final fromServer1 = await client.getBlob(
        sha256: sha256,
        serverUrls: ['http://localhost:$primaryServerPort'],
      );
      final fromServer2 = await client.getBlob(
        sha256: sha256,
        serverUrls: ['http://localhost:$secondaryServerPort'],
      );

      expect(utf8.decode(fromServer1.data), equals(myData));
      expect(utf8.decode(fromServer2.data), equals(myData));
    });

    test('mirrorToServers should mirror to multiple servers simultaneously',
        () async {
      final myData = "multi mirror test";
      final testData = Uint8List.fromList(utf8.encode(myData));

      // Upload to first server
      final uploadResponse = await client.uploadBlob(
        data: testData,
        serverUrls: ['http://localhost:$primaryServerPort'],
      );
      expect(uploadResponse.first.success, true);

      final sha256 = uploadResponse.first.descriptor!.sha256;
      final blossomUrl =
          Uri.parse('http://localhost:$primaryServerPort/$sha256');

      // Mirror to second server (we only have 2 servers in tests, but this demonstrates the capability)
      final mirrorResponse = await client.mirrorToServers(
        blossomUrl: blossomUrl,
        targetServerUrls: ['http://localhost:$secondaryServerPort'],
      );

      expect(mirrorResponse.every((r) => r.success), true);

      // Verify all servers have the blob
      final fromServer2 = await client.getBlob(
        sha256: sha256,
        serverUrls: ['http://localhost:$secondaryServerPort'],
      );

      expect(utf8.decode(fromServer2.data), equals(myData));
    });

    test('mirrorToServers should throw error if URL has no SHA256', () async {
      final invalidUrl =
          Uri.parse('http://localhost:$primaryServerPort/invalid-url');

      expect(
        () => client.mirrorToServers(
          blossomUrl: invalidUrl,
          targetServerUrls: ['http://localhost:$secondaryServerPort'],
        ),
        throwsException,
      );
    });

    test('mirrorToServers should handle server failures gracefully', () async {
      final myData = "mirror failure test";
      final testData = Uint8List.fromList(utf8.encode(myData));

      // Upload blob to first server
      final uploadResponse = await client.uploadBlob(
        data: testData,
        serverUrls: ['http://localhost:$primaryServerPort'],
      );
      expect(uploadResponse.first.success, true);

      final sha256 = uploadResponse.first.descriptor!.sha256;
      final blossomUrl =
          Uri.parse('http://localhost:$primaryServerPort/$sha256');

      // Try to mirror to both a working server and a dead one
      final mirrorResponse = await client.mirrorToServers(
        blossomUrl: blossomUrl,
        targetServerUrls: [
          'http://localhost:$secondaryServerPort',
          'http://dead.example.com',
        ],
      );

      expect(mirrorResponse.length, equals(2));

      // Find results by server URL
      final workingServer = mirrorResponse.firstWhere(
          (r) => r.serverUrl == 'http://localhost:$secondaryServerPort');
      final deadServer = mirrorResponse
          .firstWhere((r) => r.serverUrl == 'http://dead.example.com');

      expect(workingServer.success, true);
      expect(deadServer.success, false);

      // Verify working server has the blob
      final fromWorkingServer = await client.getBlob(
        sha256: sha256,
        serverUrls: ['http://localhost:$secondaryServerPort'],
      );
      expect(utf8.decode(fromWorkingServer.data), equals(myData));
    });
  });

  group("report", () {
    test('report', () async {
      final reportRsp = await client.report(
          serverUrl: 'http://localhost:${server.port}',
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
      serverUrls: ["http://localhost:${server.port}"],
    );
  });

  group('File upload and download tests', () {
    late Directory tempDir;

    setUp(() async {
      // Create a temporary directory for test files
      tempDir = await Directory.systemTemp.createTemp('blossom_test_');
    });

    tearDown(() async {
      // Clean up temporary directory and all files in it
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('uploadBlobFromFile should upload a file from disk', () async {
      // Create a test file
      final testFile = File('${tempDir.path}/test_upload.txt');
      final testContent = 'Hello from file upload test!';
      await testFile.writeAsString(testContent);

      // Upload the file
      final uploadResults = <BlobUploadResult>[];
      await for (final progress in client.uploadBlobFromFile(
        filePath: testFile.path,
        serverUrls: ['http://localhost:$primaryServerPort'],
      )) {
        if (progress.completedUploads.isNotEmpty) {
          uploadResults.addAll(progress.completedUploads);
        }
      }

      expect(uploadResults.length, greaterThan(0));
      expect(uploadResults.first.success, true);
      expect(uploadResults.first.descriptor, isNotNull);

      // Verify we can retrieve the uploaded content
      final sha256 = uploadResults.first.descriptor!.sha256;
      final getResponse = await client.getBlob(
        sha256: sha256,
        serverUrls: ['http://localhost:$primaryServerPort'],
      );

      expect(utf8.decode(getResponse.data), equals(testContent));
    });

    test('uploadBlobFromFile emits phase-aware BlobUploadProgress stream',
        () async {
      final testFile = File('${tempDir.path}/test_progress_stream.txt');
      await testFile.writeAsString('Progress stream validation payload');

      final events = <BlobUploadProgress>[];

      await for (final progress in client.uploadBlobFromFile(
        filePath: testFile.path,
        serverUrls: ['http://localhost:$primaryServerPort'],
      )) {
        events.add(progress);
      }

      expect(events, isNotEmpty);
      expect(events.first.phase, equals(UploadPhase.hashing));
      expect(events.any((e) => e.phase == UploadPhase.uploading), isTrue);
      expect(events.any((e) => e.phase == UploadPhase.mirroring), isTrue);

      final firstUploadingIndex =
          events.indexWhere((e) => e.phase == UploadPhase.uploading);
      final firstMirroringIndex =
          events.indexWhere((e) => e.phase == UploadPhase.mirroring);

      expect(firstUploadingIndex, greaterThan(0));
      expect(firstMirroringIndex, greaterThan(firstUploadingIndex));

      // Once upload starts, hashing should not appear again.
      final hasHashingAfterUpload = events
          .skip(firstUploadingIndex)
          .any((e) => e.phase == UploadPhase.hashing);
      expect(hasHashingAfterUpload, isFalse);

      // Overall percentage should map to phase bands.
      for (final event in events) {
        expect(event.percentage, inInclusiveRange(0, 100));

        switch (event.phase) {
          case UploadPhase.hashing:
            expect(event.percentage, inInclusiveRange(0, 33));
          case UploadPhase.uploading:
            expect(event.percentage, inInclusiveRange(33, 66));
          case UploadPhase.mirroring:
            expect(event.percentage, inInclusiveRange(66, 100));
        }
      }

      final lastEvent = events.last;
      expect(lastEvent.isComplete, isTrue);
      expect(lastEvent.phase, equals(UploadPhase.mirroring));
      expect(lastEvent.percentage, closeTo(100, 0.000001));
      expect(lastEvent.completedUploads.any((u) => u.success), isTrue);
    });

    test('downloadBlobToFile should download a blob to disk', () async {
      // First, upload some test data
      final testContent = 'Test content for download to file';
      final testData = Uint8List.fromList(utf8.encode(testContent));

      final uploadResponse = await client.uploadBlob(
        data: testData,
        serverUrls: ['http://localhost:$primaryServerPort'],
      );
      expect(uploadResponse.first.success, true);

      final sha256 = uploadResponse.first.descriptor!.sha256;

      // Download to a file
      final downloadFile = File('${tempDir.path}/test_download.txt');
      await client.downloadBlobToFile(
        sha256: sha256,
        outputPath: downloadFile.path,
        serverUrls: ['http://localhost:$primaryServerPort'],
      );

      // Verify the file was created and has correct content
      expect(await downloadFile.exists(), true);
      final downloadedContent = await downloadFile.readAsString();
      expect(downloadedContent, equals(testContent));
    });

    test('uploadBlobFromFile and downloadBlobToFile round trip', () async {
      // Create a test file with binary content
      final uploadFile = File('${tempDir.path}/test_binary_upload.bin');
      final testData = Uint8List.fromList(
          List.generate(1024, (i) => i % 256)); // 1KB of test data
      await uploadFile.writeAsBytes(testData);

      // Upload the file
      final uploadResults = <BlobUploadResult>[];
      await for (final progress in client.uploadBlobFromFile(
        filePath: uploadFile.path,
        serverUrls: ['http://localhost:$primaryServerPort'],
        contentType: 'application/octet-stream',
      )) {
        if (progress.completedUploads.isNotEmpty) {
          uploadResults.addAll(progress.completedUploads);
        }
      }

      expect(uploadResults.first.success, true);
      final sha256 = uploadResults.first.descriptor!.sha256;

      // Download to a different file
      final downloadFile = File('${tempDir.path}/test_binary_download.bin');
      await client.downloadBlobToFile(
        sha256: sha256,
        outputPath: downloadFile.path,
        serverUrls: ['http://localhost:$primaryServerPort'],
      );

      // Verify the downloaded file matches the original
      expect(await downloadFile.exists(), true);
      final downloadedData = await downloadFile.readAsBytes();
      expect(downloadedData, equals(testData));
    });

    test('downloadBlobToFile with authentication', () async {
      // Upload test data
      final testContent = 'Authenticated download test';
      final testData = Uint8List.fromList(utf8.encode(testContent));

      final uploadResponse = await client.uploadBlob(
        data: testData,
        serverUrls: ['http://localhost:$primaryServerPort'],
      );
      final sha256 = uploadResponse.first.descriptor!.sha256;

      // Download with authentication
      final downloadFile = File('${tempDir.path}/test_auth_download.txt');
      await client.downloadBlobToFile(
        sha256: sha256,
        outputPath: downloadFile.path,
        serverUrls: ['http://localhost:$primaryServerPort'],
        useAuth: true,
      );

      expect(await downloadFile.exists(), true);
      final downloadedContent = await downloadFile.readAsString();
      expect(downloadedContent, equals(testContent));
    });

    test('uploadBlobFromFile with multiple servers - mirrorAfterSuccess',
        () async {
      final testFile = File('${tempDir.path}/test_mirror.txt');
      final testContent = 'Mirror upload test';
      await testFile.writeAsString(testContent);

      // Upload with mirror strategy
      List<BlobUploadResult> uploadResults = const [];
      await for (final progress in client.uploadBlobFromFile(
        filePath: testFile.path,
        serverUrls: [
          'http://localhost:$primaryServerPort',
          'http://localhost:$secondaryServerPort',
        ],
        strategy: UploadStrategy.mirrorAfterSuccess,
      )) {
        if (progress.completedUploads.isNotEmpty) {
          uploadResults = progress.completedUploads;
        }
      }

      // Should have uploaded to both servers
      expect(uploadResults.length, equals(2));
      expect(uploadResults.every((r) => r.success), true);

      final sha256 = uploadResults.first.descriptor!.sha256;

      // Verify both servers have the file
      final fromServer1 = await client.getBlob(
        sha256: sha256,
        serverUrls: ['http://localhost:$primaryServerPort'],
      );
      final fromServer2 = await client.getBlob(
        sha256: sha256,
        serverUrls: ['http://localhost:$secondaryServerPort'],
      );

      expect(utf8.decode(fromServer1.data), equals(testContent));
      expect(utf8.decode(fromServer2.data), equals(testContent));
    });

    test(
        'uploadBlobFromFile mirrorAfterSuccess reports mirrorsTotal and mirrorsCompleted progression',
        () async {
      final testFile = File('${tempDir.path}/test_mirror_progress.txt');
      await testFile.writeAsString('Mirror progress test');

      final events = <BlobUploadProgress>[];
      await for (final progress in client.uploadBlobFromFile(
        filePath: testFile.path,
        serverUrls: [
          'http://localhost:$primaryServerPort',
          'http://localhost:$secondaryServerPort',
        ],
        strategy: UploadStrategy.mirrorAfterSuccess,
      )) {
        events.add(progress);
      }

      final mirrorEvents = events
          .where((e) =>
              e.phase == UploadPhase.mirroring &&
              (e.mirrorsTotal > 0 || e.mirrorsCompleted > 0))
          .toList();

      expect(mirrorEvents, isNotEmpty);

      // With 2 servers and first success strategy, only 1 mirror should be needed.
      expect(mirrorEvents.every((e) => e.mirrorsTotal == 1), isTrue);

      // Should emit start of mirroring and completion of mirroring.
      expect(mirrorEvents.any((e) => e.mirrorsCompleted == 0), isTrue);
      expect(mirrorEvents.any((e) => e.mirrorsCompleted == e.mirrorsTotal),
          isTrue);

      // Progression should be monotonic.
      for (var i = 1; i < mirrorEvents.length; i++) {
        expect(
          mirrorEvents[i].mirrorsCompleted,
          greaterThanOrEqualTo(mirrorEvents[i - 1].mirrorsCompleted),
        );
      }
    });

    test('downloadBlobToFile should handle server fallback', () async {
      // Upload to one server
      final testContent = 'Fallback test';
      final testData = Uint8List.fromList(utf8.encode(testContent));

      final uploadResponse = await client.uploadBlob(
        data: testData,
        serverUrls: ['http://localhost:$primaryServerPort'],
      );
      final sha256 = uploadResponse.first.descriptor!.sha256;

      // Try to download with fallback servers
      final downloadFile = File('${tempDir.path}/test_fallback_download.txt');
      await client.downloadBlobToFile(
        sha256: sha256,
        outputPath: downloadFile.path,
        serverUrls: [
          'http://dead.example.com',
          'http://localhost:$primaryServerPort',
          'http://another-dead.example.com',
        ],
      );

      expect(await downloadFile.exists(), true);
      final downloadedContent = await downloadFile.readAsString();
      expect(downloadedContent, equals(testContent));
    });
  });
}
