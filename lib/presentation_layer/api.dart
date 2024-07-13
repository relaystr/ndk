import 'package:dart_ndk/presentation_layer/request_state.dart';
import 'package:dart_ndk/presentation_layer/request_config.dart';

import 'init.dart';
import 'request_response.dart';

// some global obj that schuld be kept in memory by lib user
class OurApi {
  // placeholder
  dynamic someConfig;

  // global initialization use to access rdy repositories
  final Initialization _initialization = Initialization();

  // init db

  // global state

  // map of active request states

  OurApi(this.someConfig);

  /// ! this is just an example
  RequestResponse requestNostrEvent(RequestConfig config) {
    RequestState state = RequestState(config);

    final responseStream = state.stream;
    // calls uncase with config
    return RequestResponse(responseStream);
  }

  /// ! this is just an example
  /// event is event to publish
  /// broadcast config (could be optional) defines relays to broadcast to
  Future<dynamic> broadcastEvent(dynamic event, dynamic broadcastConfig) {
    // calls uncase with config
    throw UnimplementedError();
  }
}
