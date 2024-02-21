import 'package:dart_ndk/relay.dart';
import 'package:dart_ndk/request.dart';

List<Relay> SEED_RELAYs = [
  Relay('wss://relay.camelus.app'),
  Relay('wss://relay.snort.social'),
  Relay('wss://relay.damus.io'),
  Relay('wss://nostr.lu.ke'),
  Relay('wss://relay.mostr.pub')
];

class RelayJitManager {
  /// If you request anything from the nostr network put it here and
  /// the relay jit manager will try to find the right relay and use it
  /// if no relay is found the request will be blasted to all connected relays (on start seed Relays)
  handleRequest(NostrRequest request) {}
}
