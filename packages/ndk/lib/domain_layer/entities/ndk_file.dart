import 'dart:typed_data';

class NdkFile {
  final Uint8List data;
  final String? sha256;
  final String? mimeType;
  final int? size;

  NdkFile({
    required this.data,
    this.mimeType,
    this.size,
    this.sha256,
  });
}
