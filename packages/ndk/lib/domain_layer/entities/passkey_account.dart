import 'dart:convert';
import 'dart:typed_data';

/// Public metadata for reopening a specific identity. Contains no secret key.
class PasskeyAccount {
  final String rpId;
  final Uint8List credentialId;
  final String pubkey;

  /// Explicit algorithm; absent metadata never authorizes a legacy derivation.
  final String mode;
  final int? parameterSet;

  PasskeyAccount({
    required this.rpId,
    required Uint8List credentialId,
    required this.pubkey,
    required this.mode,
    this.parameterSet,
  }) : credentialId = Uint8List.fromList(credentialId).asUnmodifiableView() {
    validateRpId(rpId);
    if (!['derived', 'stored', 'legacyNosskeyDirect'].contains(mode) ||
        (mode == 'derived'
            ? ![1, 2].contains(parameterSet)
            : parameterSet != null)) {
      throw ArgumentError('Invalid passkey mode metadata');
    }
    if (credentialId.isEmpty ||
        credentialId.length > 1024 ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(pubkey)) {
      throw ArgumentError('Invalid passkey account metadata');
    }
  }

  static void validateRpId(String rpId) {
    if (rpId.isEmpty ||
        rpId.length > 253 ||
        !RegExp(
          r'^[a-zA-Z0-9](?:[a-zA-Z0-9.-]*[a-zA-Z0-9])?$',
        ).hasMatch(rpId)) {
      throw ArgumentError('Invalid relying party ID');
    }
  }

  Map<String, dynamic> toJson() => {
    'rpId': rpId,
    'credentialId': base64Url.encode(credentialId),
    'pubkey': pubkey,
    'mode': mode,
    if (parameterSet != null) 'parameterSet': parameterSet,
  };

  factory PasskeyAccount.fromJson(Map<String, dynamic> json) {
    final encoded = json['credentialId'];
    if (encoded is! String || encoded.isEmpty || encoded.length > 1368) {
      throw const FormatException('Invalid passkey credential ID');
    }
    final rpId = json['rpId'];
    final pubkey = json['pubkey'];
    final mode = json['mode'];
    final parameterSet = json['parameterSet'];
    if (rpId is! String ||
        pubkey is! String ||
        mode is! String ||
        (parameterSet != null && parameterSet is! int)) {
      throw const FormatException('Invalid passkey account metadata');
    }
    try {
      return PasskeyAccount(
        rpId: rpId,
        credentialId: base64Url.decode(encoded),
        pubkey: pubkey,
        mode: mode,
        parameterSet: parameterSet as int?,
      );
    } on ArgumentError {
      throw const FormatException('Invalid passkey account metadata');
    }
  }
}
