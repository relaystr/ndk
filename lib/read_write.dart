import 'package:dart_ndk/nips/nip65/read_write_marker.dart';

enum RelayDirection {
  read,
  write;

  bool matchesMarker(ReadWriteMarker marker) {
    return this==RelayDirection.read && marker.isRead || this ==RelayDirection.write && marker.isWrite;
  }
}
