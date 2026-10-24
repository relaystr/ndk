import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:ndk/ndk.dart';

void validatePasskeyAuthData(Uint8List data, String rpId) {
  final expected = sha256.convert(utf8.encode(rpId)).bytes;
  if (data.length < 37 ||
      !equalPasskeyBytes(data.sublist(0, 32), expected) ||
      (data[32] & 0x05) != 0x05) {
    throw const FormatException('Invalid passkey authenticator data');
  }
}

void validatePasskeyClientData(
  String encoded,
  Uint8List challenge,
  String type,
) {
  final data = jsonDecode(utf8.decode(decodePasskeyBytes(encoded)));
  if (data is! Map ||
      data['type'] != type ||
      data['challenge'] is! String ||
      !equalPasskeyBytes(
        decodePasskeyBytes(data['challenge'] as String),
        challenge,
      )) {
    throw const FormatException('Invalid passkey client data');
  }
}

bool equalPasskeyBytes(List<int> first, List<int> second) {
  if (first.length != second.length) return false;
  for (var i = 0; i < first.length; i++) {
    if (first[i] != second[i]) return false;
  }
  return true;
}

String encodePasskeyBytes(Uint8List bytes) =>
    base64Url.encode(bytes).replaceAll('=', '');

PasskeyCredential passkeyCredential(
  String rawId,
  Map<String?, Object?>? extensions, {
  String? userHandle,
}) {
  final id = decodePasskeyBytes(rawId);
  if (id.isEmpty) {
    throw const FormatException('Missing passkey credential ID');
  }
  Uint8List? output;
  bool? enabled;
  final prf = extensions?['prf'];
  if (prf is Map) {
    final flag = prf['enabled'];
    if (flag != null && flag is! bool) {
      throw const FormatException('Invalid passkey PRF enabled flag');
    }
    enabled = flag as bool?;
    final results = prf['results'];
    if (results is Map && results.containsKey('first')) {
      final first = results['first'];
      if (first is! String) {
        throw const FormatException('Invalid passkey PRF output');
      }
      output = decodePasskeyBytes(first);
      if (output.length != 32) {
        throw const FormatException('Invalid passkey PRF output length');
      }
    }
  }
  return PasskeyCredential(
    credentialId: id,
    prfOutput: output,
    prfEnabled: enabled,
    userHandle: userHandle == null || userHandle.isEmpty
        ? null
        : decodePasskeyBytes(userHandle),
  );
}

Uint8List decodePasskeyBytes(String encoded) =>
    base64Url.decode(base64Url.normalize(encoded));
