import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:ndk/data_layer/io/file_io_native.dart';
import 'package:test/test.dart';

void main() {
  group('FileIO - computeFileHash', () {
    late Directory tempDir;
    late FileIONative fileIO;

    setUp(() async {
      // Create a temporary directory for testing
      tempDir = await Directory.systemTemp.createTemp('file_io_test_');
      fileIO = FileIONative();
    });

    tearDown(() async {
      // Clean up temporary directory
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('should compute correct SHA256 hash for small file', () async {
      // Create test file with known content
      final testContent = 'Hello, World!';
      final testBytes = Uint8List.fromList(testContent.codeUnits);
      final testFile = File('${tempDir.path}/test_small.txt');
      await testFile.writeAsBytes(testBytes);

      // Compute hash using FileIO method (chunked)
      final chunkedHash = await fileIO.computeFileHash(testFile.path);

      // Compute hash using traditional in-memory method
      final inMemoryHash = sha256.convert(testBytes).toString();

      // Both methods should produce the same hash
      expect(chunkedHash, equals(inMemoryHash));
      expect(chunkedHash.length, equals(64)); // SHA256 hash is 64 hex chars
    });

    test('should compute correct SHA256 hash for larger file', () async {
      // Create a larger test file (1MB)
      final testBytes = Uint8List(1024 * 1024);
      // Fill with some pattern
      for (var i = 0; i < testBytes.length; i++) {
        testBytes[i] = i % 256;
      }
      final testFile = File('${tempDir.path}/test_large.bin');
      await testFile.writeAsBytes(testBytes);

      // Compute hash using FileIO method (chunked)
      final chunkedHash = await fileIO.computeFileHash(testFile.path);

      // Compute hash using traditional in-memory method
      final inMemoryHash = sha256.convert(testBytes).toString();

      // Both methods should produce the same hash
      expect(chunkedHash, equals(inMemoryHash));
    });

    test('should compute correct SHA256 hash for empty file', () async {
      // Create empty test file
      final testBytes = Uint8List(0);
      final testFile = File('${tempDir.path}/test_empty.txt');
      await testFile.writeAsBytes(testBytes);

      // Compute hash using FileIO method (chunked)
      final chunkedHash = await fileIO.computeFileHash(testFile.path);

      // Compute hash using traditional in-memory method
      final inMemoryHash = sha256.convert(testBytes).toString();

      // Both methods should produce the same hash
      expect(chunkedHash, equals(inMemoryHash));
      // Known SHA256 hash of empty file
      expect(
        chunkedHash,
        equals(
            'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'),
      );
    });

    test('should compute correct hash for file with specific byte patterns',
        () async {
      // Create test file with repeating pattern
      final pattern = [0xFF, 0x00, 0xAA, 0x55];
      final testBytes = Uint8List(1000);
      for (var i = 0; i < testBytes.length; i++) {
        testBytes[i] = pattern[i % pattern.length];
      }
      final testFile = File('${tempDir.path}/test_pattern.bin');
      await testFile.writeAsBytes(testBytes);

      // Compute hash using FileIO method (chunked)
      final chunkedHash = await fileIO.computeFileHash(testFile.path);

      // Compute hash using traditional in-memory method
      final inMemoryHash = sha256.convert(testBytes).toString();

      // Both methods should produce the same hash
      expect(chunkedHash, equals(inMemoryHash));
    });

    test('should handle multi-MB files efficiently', () async {
      // Create a 5MB test file
      final chunkSize = 1024 * 1024; // 1MB chunks
      final testFile = File('${tempDir.path}/test_5mb.bin');
      final sink = testFile.openWrite();

      // Write 5MB of data
      for (var i = 0; i < 5; i++) {
        final chunk = Uint8List(chunkSize);
        for (var j = 0; j < chunk.length; j++) {
          chunk[j] = (i * chunkSize + j) % 256;
        }
        sink.add(chunk);
      }
      await sink.flush();
      await sink.close();

      // Compute hash using FileIO method (chunked)
      final chunkedHash = await fileIO.computeFileHash(testFile.path);

      // Read file in memory and compute hash for comparison
      final fileBytes = await testFile.readAsBytes();
      final inMemoryHash = sha256.convert(fileBytes).toString();

      // Both methods should produce the same hash
      expect(chunkedHash, equals(inMemoryHash));
    });

    test('should throw error for non-existent file', () async {
      final nonExistentPath = '${tempDir.path}/does_not_exist.txt';

      // Should throw an error when trying to hash non-existent file
      expect(
        () => fileIO.computeFileHash(nonExistentPath),
        throwsA(isA<FileSystemException>()),
      );
    });
  });
}
