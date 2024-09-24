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

/// Main entry point for the NDK (Nostr Development Kit) library.
///
/// This file contains the primary class [Ndk] which provides access to various
/// Nostr-related functionalities/usecases and manages the global state of the application.
class Ndk {
  /// Configuration for the NDK instance
  final NdkConfig config;

  /// Global state shared across the application
  static final GlobalState _globalState = GlobalState();

  /// Internal initialization object for setting up repositories and usecases
  final Initialization _initialization;

  /// Creates a new instance of [Ndk] with the given [config]
  Ndk(this.config)
      : _initialization = Initialization(
          config: config,
          globalState: _globalState,
        );

  /// Provides access to low-level Nostr requests.
  ///
  /// Use this to directly query or subscribe to notes from the Nostr network.
  /// Available methods include query() and subscription()
  Requests get requests => _initialization.requests;

  RelayManager get relays => _initialization.relayManager;

  /// Handles operations related to user follows
  ///
  /// Use getContactList() to retrieve contact lists
  Follows get follows => _initialization.follows;

  /// user metadata operations
  Metadatas get metadatas => _initialization.metadatas;

  /// user relay lists usecase
  UserRelayLists get userRelayLists => _initialization.userRelayLists;

  /// Manages various types of lists in the Nostr network
  Lists get lists => _initialization.lists;

  /// calculate relay set
  RelaySets get relaySets => _initialization.relaySets;

  /// Changes the event verifier used by the NDK instance
  ///
  /// This method allows for hot-swapping the [EventVerifier] implementation
  ///
  /// [newEventVerifier] The new [EventVerifier] to be used
  changeEventVerifier(EventVerifier newEventVerifier) {
    config.eventVerifier = newEventVerifier;
  }

  /// Changes the event signer used by the NDK instance
  ///
  /// This method allows for hot-swapping the [EventSigner] implementation
  ///
  /// [newEventSigner] The new [EventSigner] to be used. Can be null to remove the current signer
  changeEventSigner(EventSigner? newEventSigner) {
    config.eventSigner = newEventSigner;
  }

  /// **********************************************************************************************************

  /// *************************************************************************************************
  // coverage:ignore-start

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
  // coverage:ignore-end
}
