import 'package:dart_ndk/dart_ndk.dart';

import '../domain_layer/repositories/cache_manager.dart';
import '../domain_layer/repositories/event_verifier.dart';

class NdkConfig {
  EventVerifier eventVerifier;
  EventSigner eventSigner;
  CacheManager cache;
  NdkEngine engine;

  NdkConfig({
    required this.eventVerifier,
    required this.eventSigner,
    required this.cache,
    this.engine = NdkEngine.LISTS,
  });
}

// ignore: constant_identifier_names
enum NdkEngine { LISTS, JIT }
