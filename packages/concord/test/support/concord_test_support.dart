import 'dart:typed_data';

import 'package:concord/src/core/encoding.dart';

/// A 64-char lowercase hex value filled with byte [fill].
String hex32(int fill) =>
    bytesToHex(Uint8List.fromList(List.filled(32, fill & 0xff)));

/// A raw 32-byte block filled with [fill].
Uint8List bytes32(int fill) => Uint8List.fromList(List.filled(32, fill & 0xff));
