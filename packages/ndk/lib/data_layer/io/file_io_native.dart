import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../../domain_layer/entities/file_hash_progress.dart';
import 'file_io.dart';

/// Native platform implementation using dart:io
/// Works on: Windows, macOS, Linux, Android, iOS
class FileIONative implements FileIO {
  @override
  Stream<Uint8List> readFileAsStream(String filePath, {int chunkSize = 8192}) {
    final file = File(filePath);
    return file.openRead().map((chunk) => Uint8List.fromList(chunk));
  }

  @override
  Future<void> writeFile(String filePath, Uint8List data) async {
    final file = File(filePath);
    await file.create(recursive: true);
    await file.writeAsBytes(data);
  }

  @override
  Future<void> writeFileStream(
      String filePath, Stream<Uint8List> dataStream) async {
    final file = File(filePath);
    await file.create(recursive: true);
    final sink = file.openWrite();

    await for (final chunk in dataStream) {
      sink.add(chunk);
    }

    await sink.flush();
    await sink.close();
  }

  @override
  Future<int> getFileSize(String filePath) async {
    final file = File(filePath);
    return await file.length();
  }

  @override
  Future<bool> fileExists(String filePath) async {
    final file = File(filePath);
    return await file.exists();
  }

  @override
  Future<Uint8List> readFile(String filePath) async {
    final file = File(filePath);
    return await file.readAsBytes();
  }

  @override
  Stream<FileHashProgress> computeFileHash(String filePath) async* {
    final file = File(filePath);
    final totalBytes = await file.length();

    final digestSink = _DigestSink();
    final input = sha256.startChunkedConversion(digestSink);

    int processedBytes = 0;
    yield FileHashProgress(
      processedBytes: processedBytes,
      totalBytes: totalBytes,
    );

    await for (final chunk in file.openRead()) {
      input.add(chunk);
      processedBytes += chunk.length;
      yield FileHashProgress(
        processedBytes: processedBytes,
        totalBytes: totalBytes,
      );
    }

    input.close();

    yield FileHashProgress(
      processedBytes: totalBytes,
      totalBytes: totalBytes,
      isComplete: true,
      hash: digestSink.value?.toString(),
    );
  }
}

class _DigestSink implements Sink<Digest> {
  Digest? value;

  @override
  void add(Digest data) {
    value = data;
  }

  @override
  void close() {}
}
