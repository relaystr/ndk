import 'dart:typed_data';

/// Platform-agnostic file I/O interface for reading and writing files
/// Implementations use dart:io for native and dart:html for web
abstract class FileIO {
  /// Reads a file in chunks and returns a stream of bytes
  /// [chunkSize] determines the size of each chunk (default 8KB)
  Stream<Uint8List> readFileAsStream(String filePath, {int chunkSize = 8192});

  /// Writes bytes to a file at the given path
  /// Creates the file if it doesn't exist, overwrites if it does
  Future<void> writeFile(String filePath, Uint8List data);

  /// Writes a stream of bytes to a file at the given path
  /// Creates the file if it doesn't exist, overwrites if it does
  Future<void> writeFileStream(String filePath, Stream<Uint8List> dataStream);

  /// Gets the size of a file in bytes
  Future<int> getFileSize(String filePath);

  /// Checks if a file exists at the given path
  Future<bool> fileExists(String filePath);

  /// Reads entire file into memory as Uint8List
  Future<Uint8List> readFile(String filePath);
}
