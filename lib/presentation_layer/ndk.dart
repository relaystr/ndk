import '../domain_layer/entities/global_state.dart';
import '../domain_layer/entities/nip_01_event.dart';
import '../domain_layer/repositories/event_signer.dart';
import '../domain_layer/repositories/event_verifier.dart';
import '../domain_layer/usecases/follows/follows.dart';
import '../domain_layer/usecases/lists/lists.dart';
import '../domain_layer/usecases/metadatas/metadatas.dart';
import '../domain_layer/usecases/relay_manager.dart';
import '../domain_layer/usecases/relay_sets/relay_sets.dart';
import '../domain_layer/usecases/requests/requests.dart';
import '../domain_layer/usecases/user_relay_lists/user_relay_lists.dart';
import '../shared/nips/nip09/deletion.dart';
import '../shared/nips/nip25/reactions.dart';
import 'init.dart';
import 'ndk_config.dart';

// some global obj that schuld be kept in memory by lib user
class Ndk {
  // placeholder
  final NdkConfig config;
  static final GlobalState globalState = GlobalState();

  // global initialization use to access rdy repositories
  final Initialization _initialization;

  Ndk(this.config)
      : _initialization = Initialization(
          config: config,
          globalState: globalState,
        );

  /// low level nostr requests
  /// if you want directly query or subscribe to notes from the nostr network
  /// .query() .subscription()
  Requests get requests => _initialization.requests;

  RelayManager get relays => _initialization.relayManager;

  /// retrieval of contact lists .getContactList()
  Follows get follows => _initialization.follows;
  Metadatas get metadatas => _initialization.metadatas;
  UserRelayLists get userRelayLists => _initialization.userRelayLists;
  Lists get lists => _initialization.lists;
  RelaySets get relaySets => _initialization.relaySets;

  /// hot swap EventVerifier
  changeEventVerifier(EventVerifier newEventVerifier) {
    config.eventVerifier = newEventVerifier;
  }

  /// hot swap EventSigner
  changeEventSigner(EventSigner? newEventSigner) {
    config.eventSigner = newEventSigner;
  }

  /// **********************************************************************************************************

  /// *************************************************************************************************

  Future<Nip01Event> broadcastReaction(String eventId, Iterable<String> relays,
      {String reaction = "+"}) async {
    if (config.eventSigner == null) {
      throw Exception("event signer required for broadcasting signed events");
    }
    Nip01Event event = Nip01Event(
        pubKey: config.eventSigner!.getPublicKey(),
        kind: Reaction.KIND,
        tags: [
          ["e", eventId]
        ],
        content: reaction,
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000);
    await broadcastEvent(event, relays);
    return event;
  }

  Future<Nip01Event> broadcastDeletion(
      String eventId, Iterable<String> relays, EventSigner signer) async {
    if (config.eventSigner == null) {
      throw Exception("event signer required for broadcasting signed events");
    }
    Nip01Event event = Nip01Event(
        pubKey: signer.getPublicKey(),
        kind: Deletion.KIND,
        tags: [
          ["e", eventId]
        ],
        content: "delete",
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000);
    await broadcastEvent(event, relays);
    return event;
  }

  List<String> blockedRelays() {
    return _initialization.relayManager.blockedRelays;
  }

  Future<void> broadcastEvent(
      Nip01Event event, Iterable<String> broadcastRelays,
      {EventSigner? signer}) async {
    if (config.eventSigner != null && config.eventSigner!.canSign()) {
      return await _initialization.relayManager
          .broadcastEvent(event, broadcastRelays, config.eventSigner!);
    }
    throw Exception("event signer required for broadcasting signed events");
  }
}
