import 'package:dart_ndk/domain_layer/entities/request_state.dart';
import 'package:dart_ndk/presentation_layer/request_config.dart';

// some global obj that schuld be kept in memory by lib user
class OurApi {
  // placeholder
  dynamic someConfig;

  OurApi(this.someConfig);

  /// ! this is just an example
  Stream requestNostrEvent(RequestConfig config) {
    RequestState state = RequestState(config);
    // calls uncase with config
    return state.stream;
  }

  /// ! this is just an example
  /// event is event to publish
  /// broadcast config (could be optional) defines relays to broadcast to
  Future<dynamic> broadcastEvent(dynamic event, dynamic broadcastConfig) {
    // calls uncase with config
    throw UnimplementedError();
  }
}
