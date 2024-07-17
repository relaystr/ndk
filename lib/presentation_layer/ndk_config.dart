import '../domain_layer/repositories/cache_manager.dart';
import '../domain_layer/repositories/event_verifier_repository.dart';

class NdkConfig {
  EventVerifier eventVerifier;
  CacheManager cache;
  NdkEngine engine;

  NdkConfig({
    required this.eventVerifier,
    required this.cache,
    this.engine = NdkEngine.LISTS,
  });
}

// ignore: constant_identifier_names
enum NdkEngine { LISTS, JIT }
