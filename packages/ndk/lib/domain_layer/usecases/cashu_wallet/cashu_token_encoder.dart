import 'dart:convert';

import 'package:cbor/cbor.dart';

import '../../entities/cashu/wallet_cashu_token.dart';

class CashuTokenEncoder {
  static String encodeTokenV4({
    required WalletCashuToken token,
  }) {
    final v4Prefix = 'cashuB';

    final json = token.toV4Json();
    final myCbor = CborValue(json);
    final base64String = base64.encode(cbor.encode(myCbor));
    String base64URL = base64urlFromBase64(base64String);
    return v4Prefix + base64URL;
  }

  static String base64urlFromBase64(String base64String) {
    String output = base64String.replaceAll('+', '-').replaceAll('/', '_');
    return output.split('=')[0];
  }
}
