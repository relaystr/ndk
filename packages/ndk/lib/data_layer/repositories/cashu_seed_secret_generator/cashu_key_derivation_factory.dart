import '../../../domain_layer/repositories/cashu_seed_secret.dart';
import 'cashu_key_derivation_impl_stub.dart'
    if (dart.library.js_interop) 'cashu_key_derivation_impl_web.dart'
    if (dart.library.io) 'cashu_key_derivation_impl_io.dart';

/// Factory to create the appropriate CashuKeyDerivation implementation
/// based on the platform (web vs native)
CashuKeyDerivation createCashuKeyDerivation() {
  return createPlatformCashuKeyDerivation();
}
