import '../../../presentation_layer/ndk_request.dart';
import '../../entities/request_state.dart';
import '../../repositories/cache_manager.dart';

class CacheRead {
  final CacheManager cacheManager;

  CacheRead(this.cacheManager);

  /// find matching events in cache return them and remove/update unresolved filters
  resolveUnresolvedFilters({
    required RequestState requestState,
  }) {
    final unresolved = requestState.unresolvedFilters;
    for (var filter in unresolved) {}
  }
}
