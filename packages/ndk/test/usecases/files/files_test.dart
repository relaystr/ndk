import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import 'package:ndk/data_layer/data_sources/http_request.dart';
import 'package:ndk/data_layer/repositories/blossom/blossom_impl.dart';
import 'package:ndk/domain_layer/usecases/files/files.dart';
import 'package:test/test.dart';

import '../../mocks/mock_blossom_server.dart';

void main() {
  late MockBlossomServer server;
  late Files client;

  setUp(() async {
    server = MockBlossomServer(port: 3000);
    await server.start();

    final blossomRepo = BlossomRepositoryImpl(
      client: HttpRequestDS(http.Client()),
      serverUrls: ['http://localhost:3000'],
    );
    client = Files(blossomRepo);
  });

  tearDown(() async {
    await server.stop();
  });

  group('Blossom Client Integration Tests', () {
    test('Upload and retrieve blob', () async {
      final testData = Uint8List.fromList(utf8.encode('Hello, Blossom!'));
      final authEvent = createTestAuthEvent('upload');

      // Upload blob
      final uploadResponse = await client.uploadBlob(
        data: testData,
        //authorization: authEvent,
      );
      expect(uploadResponse.first.success, true);

      final sha256 = uploadResponse.first.descriptor!.sha256;

      // Retrieve blob
      final getResponse = await client.getBlob(sha256);
      expect(utf8.decode(getResponse), equals('Hello, Blossom!'));
    });

    test('List blobs for user', () async {
      // Upload some test blobs first
      final testData1 = Uint8List.fromList(utf8.encode('Test 1'));
      final testData2 = Uint8List.fromList(utf8.encode('Test 2'));

      await client.uploadBlob(
        data: testData1,
        //authorization: createTestAuthEvent('upload'),
      );
      await client.uploadBlob(
        data: testData2,
        //authorization: createTestAuthEvent('upload'),
      );

      final listResponse = await client.listBlobs('test_pubkey');

      expect(listResponse.length, equals(2));
    });
  });
}

Map<String, dynamic> createTestAuthEvent(String type) {
  return {
    'kind': 24242,
    'pubkey': 'test_pubkey',
    'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    'tags': [
      ['t', type],
      ['x', 'test_hash'],
    ],
    'sig': 'test_signature',
  };
}
