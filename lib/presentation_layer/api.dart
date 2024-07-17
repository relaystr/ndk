import 'package:dart_ndk/presentation_layer/concurrency_check.dart';
import 'package:dart_ndk/presentation_layer/request_state.dart';
import 'package:dart_ndk/presentation_layer/ndk_request.dart';

import 'init.dart';
import 'ndk_config.dart';
import 'request_response.dart';

// some global obj that schuld be kept in memory by lib user
class OurApi {
  // placeholder
  NdkConfig ndkConfig;

  // global initialization use to access rdy repositories
  final Initialization _initialization = Initialization();

  OurApi(this.ndkConfig);

  /// ! this is just an example
  RequestResponse requestNostrEvent(NdkRequest config) {
    RequestState requestState = RequestState(config);

    final responseStream = requestState.stream;

    final response = RequestResponse(responseStream);

    final concurrency = ConcurrencyCheck(_initialization.globalState);

    // concurrency check - check if request is inFlight
    final streamWasReplaced = concurrency.check(requestState);
    if (streamWasReplaced) {
      return response;
    }

    // todo caching middleware

    // todo engine impl for unresolved?

    // calls uncase with config
    return response;
  }

  /// ! this is just an example
  /// event is event to publish
  /// broadcast config (could be optional) defines relays to broadcast to
  Future<dynamic> broadcastEvent(dynamic event, dynamic broadcastConfig) {
    // calls uncase with config
    throw UnimplementedError();
  }
}
