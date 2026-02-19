import 'dart:typed_data';

import '../../domain_layer/entities/file_hash_progress.dart';
import 'file_io.dart';

/// Stub implementation that should never be used
/// The conditional exports should ensure the correct platform implementation is used
class FileIONative implements FileIO {
  FileIONative() {
    throw UnsupportedError('Cannot create FileIO without dart:html or dart:io');
  }

  @override
  Stream<Uint8List> readFileAsStream(String filePath, {int chunkSize = 8192}) {
    throw UnimplementedError();
  }

  @override
  Future<void> writeFile(String filePath, Uint8List data) {
    throw UnimplementedError();
  }

  @override
  Future<void> writeFileStream(String filePath, Stream<Uint8List> dataStream) {
    throw UnimplementedError();
  }

  @override
  Future<int> getFileSize(String filePath) {
    throw UnimplementedError();
  }

  @override
  Future<bool> fileExists(String filePath) {
    throw UnimplementedError();
  }

  @override
  Future<Uint8List> readFile(String filePath) {
    throw UnimplementedError();
  }

  @override
  Stream<FileHashProgress> computeFileHash(String filePath) {
    throw UnimplementedError();
  }
}

/// Stub implementation for web that should never be used
class FileIOWeb implements FileIO {
  FileIOWeb() {
    throw UnsupportedError('Cannot create FileIO without dart:html or dart:io');
  }

  @override
  Stream<Uint8List> readFileAsStream(String filePath, {int chunkSize = 8192}) {
    throw UnimplementedError();
  }

  @override
  Future<void> writeFile(String filePath, Uint8List data) {
    throw UnimplementedError();
  }

  @override
  Future<void> writeFileStream(String filePath, Stream<Uint8List> dataStream) {
    throw UnimplementedError();
  }

  @override
  Future<int> getFileSize(String filePath) {
    throw UnimplementedError();
  }

  @override
  Future<bool> fileExists(String filePath) {
    throw UnimplementedError();
  }

  @override
  Future<Uint8List> readFile(String filePath) {
    throw UnimplementedError();
  }

  @override
  Stream<FileHashProgress> computeFileHash(String filePath) {
    throw UnimplementedError();
  }
}
