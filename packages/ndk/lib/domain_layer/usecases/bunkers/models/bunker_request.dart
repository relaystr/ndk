import 'package:ndk_core/shared/nips/nip01/helpers.dart';

import 'package:ndk_core/domain_layer/entities/pending_signer_request.dart';
export 'package:ndk_core/domain_layer/entities/pending_signer_request.dart'
    show SignerMethod;

class BunkerRequest {
  static const int kKind = 24133;

  final String id;
  final SignerMethod method;
  final List<String> params;

  BunkerRequest({required this.method, String? id, List<String>? params})
    : id = id ?? Helpers.getRandomString(16),
      params = params ?? [];

  Map<String, dynamic> toJson() {
    return {'id': id, 'method': method.protocolString, 'params': params};
  }
}
