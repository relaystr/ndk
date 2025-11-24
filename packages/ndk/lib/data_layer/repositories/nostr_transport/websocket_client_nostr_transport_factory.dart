import 'package:ndk/data_layer/repositories/nostr_transport/websocket_client_nostr_transport.dart';
import 'package:ndk/data_layer/repositories/nostr_transport/websocket_isolate_nostr_transport.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_client/web_socket_client.dart';

import '../../../domain_layer/repositories/nostr_transport.dart';
import '../../../shared/helpers/relay_helper.dart';
import '../../data_sources/websocket_channel.dart';
import '../../data_sources/websocket_client.dart';

class WebSocketClientNostrTransportFactory implements NostrTransportFactory {
  final bool useIsolate;

  WebSocketClientNostrTransportFactory({this.useIsolate = true});

  @override
  NostrTransport call(String url, Function? onReconnect) {
    final myUrl = cleanRelayUrl(url);

    if (myUrl == null) {
      throw Exception("relayUrl is not parsable");
    }

    // Use isolate-based transport for better performance
    if (useIsolate) {
      return WebSocketIsolateNostrTransport(myUrl, onReconnect);
    }

    // Fallback to regular transport
    final backoff = BinaryExponentialBackoff(
        initial: Duration(seconds: 1), maximumStep: 10);
    final client = WebSocket(Uri.parse(myUrl), backoff: backoff);

    final WebsocketDSClient myDataSource = WebsocketDSClient(client, myUrl);
    return WebSocketClientNostrTransport(myDataSource, onReconnect);
  }
}
