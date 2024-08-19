import '../domain_layer/entities/contact_list.dart';
import '../domain_layer/entities/filter.dart';
import '../domain_layer/entities/metadata.dart';
import '../domain_layer/entities/read_write.dart';
import '../domain_layer/entities/relay_set.dart';
import '../domain_layer/repositories/event_signer.dart';
import '../domain_layer/repositories/event_verifier.dart';
import '../domain_layer/usecases/relay_manager.dart';
import '../shared/logger/logger.dart';
import '../shared/nips/nip01/helpers.dart';
import 'concurrency_check.dart';
import 'global_state.dart';
import 'init.dart';
import 'ndk_config.dart';
import 'ndk_request.dart';
import 'request_response.dart';
import '../domain_layer/entities/request_state.dart';

// some global obj that schuld be kept in memory by lib user
class Ndk {
  // placeholder
  final NdkConfig config;
  static final GlobalState globalState = GlobalState();

  // global initialization use to access rdy repositories
  final Initialization _initialization;

  Ndk(this.config)
      : _initialization = Initialization(
          ndkConfig: config,
          globalState: globalState,
        );

  RequestResponse query({required List<Filter> filters}) {
    return requestNostrEvent(NdkRequest.query(Helpers.getRandomString(10), filters: filters));
  }

  subscription({required List<Filter> filters, String? id}) {
    return requestNostrEvent(NdkRequest.subscription(id ?? Helpers.getRandomString(10), filters: filters));
  }

  /// ! this is just an example
  RequestResponse requestNostrEvent(NdkRequest request) {
    RequestState state = RequestState(request);

    final response = RequestResponse(state.stream);

    final concurrency = ConcurrencyCheck(globalState);

    /// concurrency check - check if request is inFlight
    final streamWasReplaced = request.cacheRead && concurrency.check(state);
    if (streamWasReplaced) {
      return response;
    }

    // todo caching middleware
    // caching should write to response stream and keep track on what is unresolved to send the split filters to the engine
    if (request.cacheRead) {
      _initialization.cacheRead
          .resolveUnresolvedFilters(requestState: state);
    }

    /// handle request)

    switch (config.engine) {
      case NdkEngine.LISTS:
        //todo: discuss/implement use of unresolvedFilters
        _initialization.relayManager!.handleRequest(state);
        break;

      case NdkEngine.JIT:
        _initialization.jitEngine!.handleRequest(state);
        break;

      default:
        throw UnimplementedError("Unknown engine");
    }

    /// cache network response
    // todo: discuss use of networkController.add() in engines, its something to keep in mind and therefore bad
    if (request.cacheWrite) {
      _initialization.cacheWrite.saveNetworkResponse(
        networkController: state.networkController,
        responseController: state.controller,
      );
    } else {
      state.networkController.stream.listen((event) {
        state.controller.add(event);
      }, onDone: () {
        state.controller.close();
      }, onError:  (error) {
        Logger.log.e("⛔ $error ");
      });
    }

    return response;
  }

  Future<RelaySet> calculateRelaySet({required String name,
    required String ownerPubKey,
    required List<String> pubKeys,
    required RelayDirection direction,
    required int relayMinCountPerPubKey,
    Function(String, int, int)? onProgress}) async {
    if (_initialization.relayManager==null) {
      throw UnimplementedError("this engine doesn't support calculation of relay sets");
    }
    return await _initialization.relayManager!.calculateRelaySet(name: name, ownerPubKey: ownerPubKey, pubKeys: pubKeys, direction: direction, relayMinCountPerPubKey: relayMinCountPerPubKey);
  }

  Future<ContactList?> getContactList(String pubKey,
      {bool forceRefresh = false,
      int idleTimeout = RelayManager.DEFAULT_STREAM_IDLE_TIMEOUT}) async {
    ContactList? contactList = config.cache.loadContactList(pubKey);
    if (contactList == null || forceRefresh) {
      ContactList? loadedContactList;
      try {

        await for (final event in query(filters: [Filter(kinds: [ContactList.KIND], authors: [pubKey], limit: 1)])
            .stream) {
          if (loadedContactList == null ||
              loadedContactList.createdAt < event.createdAt) {
            loadedContactList = ContactList.fromEvent(event);
          }
        }
      } catch (e) {
        print(e);
        // probably timeout;
      }
      if (loadedContactList != null &&
          (contactList == null ||
              contactList.createdAt < loadedContactList.createdAt)) {
        loadedContactList.loadedTimestamp =
            DateTime.now().millisecondsSinceEpoch ~/ 1000;
        await config.cache.saveContactList(loadedContactList);
        contactList = loadedContactList;
      }
    }
    return contactList;
  }

  Future<Metadata?> getSingleMetadata(String pubKey,
      {bool forceRefresh = false,
      int idleTimeout = RelayManager.DEFAULT_STREAM_IDLE_TIMEOUT}) async {
    Metadata? metadata = config.cache.loadMetadata(pubKey);
    if (metadata == null || forceRefresh) {
      Metadata? loadedMetadata;
      try {
        await for (final event in query(filters: [Filter(kinds: [Metadata.KIND], authors: [pubKey], limit: 1)])
            .stream) {
          if (loadedMetadata == null ||
              loadedMetadata.updatedAt == null ||
              loadedMetadata.updatedAt! < event.createdAt) {
            loadedMetadata = Metadata.fromEvent(event);
          }
        }
      } catch (e) {
        // probably timeout;
      }
      if (loadedMetadata != null &&
          (metadata == null ||
              loadedMetadata.updatedAt == null ||
              metadata.updatedAt == null ||
              loadedMetadata.updatedAt! < metadata.updatedAt! ||
              forceRefresh)) {
        loadedMetadata.refreshedTimestamp = Helpers.now;
        await config.cache.saveMetadata(loadedMetadata);
        metadata = loadedMetadata;
      }
    }
    return metadata;
  }


  /// ! this is just an example
  /// event is event to publish
  /// broadcast config (could be optional) defines relays to broadcast to
  Future<dynamic> broadcastEvent(dynamic event, dynamic broadcastConfig) {
    // calls uncase with config
    throw UnimplementedError();
  }

  /// hot swap EventVerifier
  changeEventVerifier(EventVerifier newEventVerifier) {
    config.eventVerifier = newEventVerifier;
  }

  /// hot swap EventSigner
  changeEventSigner(EventSigner newEventSigner) {
    config.eventSigner = newEventSigner;
  }
}
