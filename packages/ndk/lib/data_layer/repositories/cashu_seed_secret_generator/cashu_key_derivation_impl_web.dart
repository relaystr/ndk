import '../../../domain_layer/repositories/cashu_seed_secret.dart';
import 'js_cashu_key_derivation.dart';

/// Web implementation - uses the JavaScript interop implementation
CashuKeyDerivation createPlatformCashuKeyDerivation() {
  return JsCashuKeyDerivation();
}
