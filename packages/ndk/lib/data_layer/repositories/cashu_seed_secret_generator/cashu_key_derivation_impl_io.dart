import '../../../domain_layer/repositories/cashu_seed_secret.dart';
import 'dart_cashu_key_derivation.dart';

/// IO (native) implementation - uses the Dart implementation
CashuKeyDerivation createPlatformCashuKeyDerivation() {
  return DartCashuKeyDerivation();
}
