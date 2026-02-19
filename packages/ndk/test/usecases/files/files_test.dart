import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ndk/domain_layer/entities/ndk_file.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

import '../../mocks/mock_blossom_server.dart';
import '../../mocks/mock_event_verifier.dart';

void main() {
  late MockBlossomServer server;
  late MockBlossomServer server2;
  late Files client;

  setUp(() async {
    server = MockBlossomServer(port: 3010);
    server2 = MockBlossomServer(port: 3011);
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

    client = ndk.files;
  });

  tearDown(() async {
    await server.stop();
    await server2.stop();
  });

  group('File Integration Tests', () {
    test('no file', () async {
      // download
      final getResponse = client.download(
        url: 'http://localhost:3000/no_file',
        serverUrls: ['http://localhost:3010'],
      );
      expect(getResponse, throwsA(isA<Exception>()));
    });

    test('Upload and retrieve file', () async {
      final testData = Uint8List.fromList(utf8.encode('Hello, File2'));

      // Upload
      final uploadResponse = await client.upload(
        file: NdkFile(data: testData, mimeType: 'text/plain'),
        serverUrls: ['http://localhost:3010'],
      );
      expect(uploadResponse.first.success, true);

      final sha256 = uploadResponse.first.descriptor!.sha256;

      // download
      final getResponse = await client.download(
        url: 'http://localhost:3010/$sha256',
        serverUrls: ['http://localhost:3010'],
      );

      expect(utf8.decode(getResponse.data), equals('Hello, File2'));
    });

    test('Upload and delete file', () async {
      final testData = Uint8List.fromList(utf8.encode('Hello, File2'));

      // Upload
      final uploadResponse = await client.upload(
        file: NdkFile(data: testData, mimeType: 'text/plain'),
        serverUrls: ['http://localhost:3010'],
      );
      expect(uploadResponse.first.success, true);

      final sha256 = uploadResponse.first.descriptor!.sha256;

      final deleteResponse = await client.delete(
        sha256: sha256,
        serverUrls: ['http://localhost:3010', 'http://localhost:3011'],
      );

      expect(deleteResponse.first.success, true);

      // download
      final getResponse = client.download(
        url: 'http://localhost:3010/$sha256',
        serverUrls: [
          'https://localhost:3011',
          'http://localhost:3010',
        ],
      );
      expect(getResponse, throwsA(isA<Exception>()));
    });

    test('checkUrl - no blossom', () async {
      // download
      final response = client.checkUrl(
        url: 'http://localhost:3000/no_blossom',
        serverUrls: ['http://localhost:3010'],
      );
      expect(response, completion('http://localhost:3000/no_blossom'));
    });

    test('checkUrl - blossom', () async {
      final testData = Uint8List.fromList(utf8.encode('check test'));

      // Upload
      final uploadResponse = await client.upload(
        file: NdkFile(data: testData, mimeType: 'text/plain'),
        serverUrls: ['http://localhost:3010'],
      );
      expect(uploadResponse.first.success, true);

      // check
      final response = client.checkUrl(
        url: 'http://localhost:3010/${uploadResponse.first.descriptor!.sha256}',
        serverUrls: [
          'https://localhost:3011',
          'http://localhost:3010',
        ],
      );
      expect(
          response,
          completion(
              'http://localhost:3010/${uploadResponse.first.descriptor!.sha256}'));
    });
  });

  group('File upload and download from/to disk tests', () {
    late Directory tempDir;

    setUp(() async {
      // Create a temporary directory for test files
      tempDir = await Directory.systemTemp.createTemp('files_test_');
    });

    tearDown(() async {
      // Clean up temporary directory and all files in it
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('uploadFromFile should upload a file from disk', () async {
      // Create a test file
      final testFile = File('${tempDir.path}/test_upload.txt');
      final testContent = 'Hello from Files.uploadFromFile!';
      await testFile.writeAsString(testContent);

      // Upload the file
      final uploadResults = <BlobUploadResult>[];
      await for (final progress in client.uploadFromFile(
        filePath: testFile.path,
        serverUrls: ['http://localhost:3010'],
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
      final getResponse = await client.download(
        url: 'http://localhost:3010/$sha256',
        serverUrls: ['http://localhost:3010'],
      );

      expect(utf8.decode(getResponse.data), equals(testContent));
    });

    test('downloadToFile should download a file to disk', () async {
      // First, upload some test data
      final testContent = 'Test content for Files.downloadToFile';
      final testData = Uint8List.fromList(utf8.encode(testContent));

      final uploadResponse = await client.upload(
        file: NdkFile(data: testData, mimeType: 'text/plain'),
        serverUrls: ['http://localhost:3010'],
      );
      expect(uploadResponse.first.success, true);

      final sha256 = uploadResponse.first.descriptor!.sha256;

      // Download to a file
      final downloadFile = File('${tempDir.path}/test_download.txt');
      await client.downloadToFile(
        url: 'http://localhost:3010/$sha256',
        outputPath: downloadFile.path,
        serverUrls: ['http://localhost:3010'],
      );

      // Verify the file was created and has correct content
      expect(await downloadFile.exists(), true);
      final downloadedContent = await downloadFile.readAsString();
      expect(downloadedContent, equals(testContent));
    });

    test('uploadFromFile and downloadToFile round trip', () async {
      // Create a test file with binary content
      final uploadFile = File('${tempDir.path}/test_binary_upload.bin');
      final testData = Uint8List.fromList(
          List.generate(2048, (i) => i % 256)); // 2KB of test data
      await uploadFile.writeAsBytes(testData);

      // Upload the file
      final uploadResults = <BlobUploadResult>[];
      await for (final progress in client.uploadFromFile(
        filePath: uploadFile.path,
        serverUrls: ['http://localhost:3010'],
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
      await client.downloadToFile(
        url: 'http://localhost:3010/$sha256',
        outputPath: downloadFile.path,
        serverUrls: ['http://localhost:3010'],
      );

      // Verify the downloaded file matches the original
      expect(await downloadFile.exists(), true);
      final downloadedData = await downloadFile.readAsBytes();
      expect(downloadedData, equals(testData));
    });

    test('downloadToFile with authentication', () async {
      // Upload test data
      final testContent = 'Authenticated download via Files';
      final testData = Uint8List.fromList(utf8.encode(testContent));

      final uploadResponse = await client.upload(
        file: NdkFile(data: testData, mimeType: 'text/plain'),
        serverUrls: ['http://localhost:3010'],
      );
      final sha256 = uploadResponse.first.descriptor!.sha256;

      // Download with authentication
      final downloadFile = File('${tempDir.path}/test_auth_download.txt');
      await client.downloadToFile(
        url: 'http://localhost:3010/$sha256',
        outputPath: downloadFile.path,
        serverUrls: ['http://localhost:3010'],
        useAuth: true,
      );

      expect(await downloadFile.exists(), true);
      final downloadedContent = await downloadFile.readAsString();
      expect(downloadedContent, equals(testContent));
    });

    test('uploadFromFile with multiple servers', () async {
      final testFile = File('${tempDir.path}/test_mirror.txt');
      final testContent = 'Mirror upload via Files';
      await testFile.writeAsString(testContent);

      // Upload with mirror strategy
      List<BlobUploadResult> uploadResults = const [];
      await for (final progress in client.uploadFromFile(
        filePath: testFile.path,
        serverUrls: [
          'http://localhost:3010',
          'http://localhost:3011',
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
      final fromServer1 = await client.download(
        url: 'http://localhost:3010/$sha256',
        serverUrls: ['http://localhost:3010'],
      );
      final fromServer2 = await client.download(
        url: 'http://localhost:3011/$sha256',
        serverUrls: ['http://localhost:3011'],
      );

      expect(utf8.decode(fromServer1.data), equals(testContent));
      expect(utf8.decode(fromServer2.data), equals(testContent));
    });

    test('downloadToFile should handle server fallback', () async {
      // Upload to one server
      final testContent = 'Fallback test via Files';
      final testData = Uint8List.fromList(utf8.encode(testContent));

      final uploadResponse = await client.upload(
        file: NdkFile(data: testData, mimeType: 'text/plain'),
        serverUrls: ['http://localhost:3010'],
      );
      final sha256 = uploadResponse.first.descriptor!.sha256;

      // Try to download with fallback servers
      final downloadFile = File('${tempDir.path}/test_fallback_download.txt');
      await client.downloadToFile(
        url: 'http://localhost:3010/$sha256',
        outputPath: downloadFile.path,
        serverUrls: [
          'http://dead.example.com',
          'http://localhost:3010',
        ],
      );

      expect(await downloadFile.exists(), true);
      final downloadedContent = await downloadFile.readAsString();
      expect(downloadedContent, equals(testContent));
    });

    test('downloadToFile should support non-blossom URLs', () async {
      // Upload a test file first so we have something to download
      final testContent = 'Direct download test';
      final testData = Uint8List.fromList(utf8.encode(testContent));

      final uploadResponse = await client.upload(
        file: NdkFile(data: testData, mimeType: 'text/plain'),
        serverUrls: ['http://localhost:3010'],
      );
      final sha256 = uploadResponse.first.descriptor!.sha256;

      // Now download using the full URL (non-blossom style)
      final downloadFile = File('${tempDir.path}/test_direct_download.txt');
      await client.downloadToFile(
        url: 'http://localhost:3010/$sha256',
        outputPath: downloadFile.path,
        serverUrls: ['http://localhost:3010'],
      );

      expect(await downloadFile.exists(), true);
      final downloadedContent = await downloadFile.readAsString();
      expect(downloadedContent, equals(testContent));
    });

    test('downloadToFile with direct non-blossom URL', () async {
      // Download a static file from a non-blossom URL
      final downloadFile = File('${tempDir.path}/test_non_blossom_url.txt');
      final directUrl = 'http://localhost:3010/static/test.txt';

      await client.downloadToFile(
        url: directUrl,
        outputPath: downloadFile.path,
      );

      expect(await downloadFile.exists(), true);
      final downloadedContent = await downloadFile.readAsString();
      expect(downloadedContent, equals('Static file content for testing'));
    });
  });
}
