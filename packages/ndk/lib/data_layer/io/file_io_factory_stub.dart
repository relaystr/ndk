import 'file_io.dart';

/// Stub implementation used when neither `dart:io` nor web interop is available.
FileIO createFileIO() {
  throw UnsupportedError('Cannot create FileIO on this platform');
}
