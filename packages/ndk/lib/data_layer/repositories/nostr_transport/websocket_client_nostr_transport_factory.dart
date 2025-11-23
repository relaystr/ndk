import 'package:ndk/data_layer/repositories/nostr_transport/websocket_client_nostr_transport.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_client/web_socket_client.dart';

import '../../../domain_layer/repositories/nostr_transport.dart';
import '../../../shared/helpers/relay_helper.dart';
import '../../data_sources/websocket_channel.dart';
import '../../data_sources/websocket_client.dart';

class WebSocketClientNostrTransportFactory implements NostrTransportFactory {
  @override
  NostrTransport call(String url, Function? onReconnect) {
    final myUrl = cleanRelayUrl(url);

    if (myUrl == null) {
      throw Exception("relayUrl is not parsable");
    }

    final backoff = BinaryExponentialBackoff(
        initial: Duration(seconds: 1), maximumStep: 10);
    final client = WebSocket(Uri.parse(myUrl), backoff: backoff);

    final WebsocketDSClient myDataSource = WebsocketDSClient(client, myUrl);
    // final WebsocketChannelDS myDataSource =
    //     WebsocketChannelDS(WebSocketChannel.connect(Uri.parse(myUrl)), myUrl);
    return WebSocketClientNostrTransport(myDataSource, onReconnect);
  }
}
