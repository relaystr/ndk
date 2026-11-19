import '../entities/cache_eviction.dart';
import 'stores/cashu_store.dart';
import 'stores/contact_list_store.dart';
import 'stores/decrypted_event_payload_store.dart';
import 'stores/event_delivery_store.dart';
import 'stores/event_store.dart';
import 'stores/filter_fetched_range_store.dart';
import 'stores/metadata_store.dart';
import 'stores/nip05_store.dart';
import 'stores/relay_set_store.dart';
import 'stores/user_relay_list_store.dart';

/// Every store NDK persists to, implemented by one backend.
///
/// Usecases depend on the stores they use. [evict], [clearAll] and [close]
/// span all of them.
abstract class CacheManager
    implements
        EventStore,
        EventDeliveryStore,
        DecryptedEventPayloadStore,
        UserRelayListStore,
        RelaySetStore,
        ContactListStore,
        MetadataStore,
        Nip05Store,
        CashuStore,
        FilterFetchedRangeStore {
  /// closes the cache manger \
  /// used to close the db
  Future<void> close();

  /// Run one eviction pass according to [policy].
  ///
  /// Backends should remove associated sidecars, provenance, and delivery state
  /// for any event they physically delete.
  Future<EvictionResult> evict(EvictionPolicy policy);

  /// Clears all cached data.
  ///
  /// **DANGER**: This will permanently delete ALL cached data including events,
  /// metadata, contact lists, relay sets, user relay lists, nip05 records,
  /// and filter fetched range records. This operation cannot be undone.
  Future<void> clearAll();
}
