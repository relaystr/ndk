import 'dart:js_interop';
import 'dart:typed_data';
import 'package:bip39_mnemonic/bip39_mnemonic.dart';
import 'package:convert/convert.dart';

import '../../../domain_layer/repositories/cashu_seed_secret.dart';
import '../../../domain_layer/usecases/cashu/cashu_seed.dart';

/// JavaScript interop bindings for cashu key derivation
@JS('cashuKeyDerivation.deriveSecretAndBlinding')
external JSObject _jsDerive(JSArray<JSNumber> seed, JSString keysetId, JSNumber counter);

@JS('cashuKeyDerivation.deriveSecret')
external JSString _jsDeriveSecret(JSArray<JSNumber> seed, JSString keysetId, JSNumber counter);

@JS('cashuKeyDerivation.deriveBlindingFactor')
external JSString _jsDeriveBlindingFactor(JSArray<JSNumber> seed, JSString keysetId, JSNumber counter);

/// Extension methods to convert Dart types to JS types
extension on Uint8List {
  JSArray<JSNumber> toJSArray() {
    final jsArray = JSArray<JSNumber>();
    for (var i = 0; i < length; i++) {
      jsArray[i] = this[i].toJS;
    }
    return jsArray;
  }
}

extension on JSObject {
  String getStringProperty(String name) {
    return (this[name.toJS] as JSString).toDart;
  }
}

/// Web implementation of CashuKeyDerivation using JavaScript interop
/// This implementation calls the JavaScript cashu_key_derivation.js module
class JsCashuKeyDerivation implements CashuKeyDerivation {
  JsCashuKeyDerivation();

  @override
  Future<CashuSeedDeriveSecretResult> deriveSecret({
    required Mnemonic mnemonic,
    required int counter,
    required String keysetId,
  }) async {
    try {
      final seed = Uint8List.fromList(mnemonic.seed);
      
      // Convert Dart types to JS types
      final jsSeed = seed.toJSArray();
      final jsKeysetId = keysetId.toJS;
      final jsCounter = counter.toJS;
      
      // Call JavaScript function
      final result = _jsDerive(jsSeed, jsKeysetId, jsCounter);
      
      // Extract results from JS object
      final secretHex = result.getStringProperty('secretHex');
      final blindingHex = result.getStringProperty('blindingHex');
      
      return CashuSeedDeriveSecretResult(
        secretHex: secretHex,
        blindingHex: blindingHex,
      );
    } catch (e) {
      throw Exception('Failed to derive cashu secret: $e');
    }
  }
}
