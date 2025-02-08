import 'dart:convert';
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
    ndk.accounts.loginPrivateKey(pubkey: key1.publicKey, privkey: key1.privateKey!);

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
  });
}
