import 'dart:io';

import 'package:web_socket_channel/io.dart';

import '../../../config/request_defaults.dart';
import '../../../domain_layer/repositories/nostr_transport.dart';
import '../../../shared/helpers/relay_helper.dart';
import '../../data_sources/websocket.dart';
import 'websocket_nostr_transport.dart';

class WebSocketNostrTransportFactory implements NostrTransportFactory {
  @override
  NostrTransport call(String url, Function? onReconnect) {
    final myUrl = cleanRelayUrl(url);

    if (myUrl == null) {
      throw Exception("relayUrl is not parsable");
    }

    final wsUrl = Uri.parse(myUrl);
    // HttpClient httpClient = HttpClient();
    // httpClient.userAgent = RequestDefaults.DEFAULT_USER_AGENT;
    final IOWebSocketChannel webSocketChannel = IOWebSocketChannel.connect(
      wsUrl,
      // customClient: httpClient
    );
    final WebsocketDS myDataSource = WebsocketDS(webSocketChannel);
    return WebSocketNostrTransport(myDataSource);
  }
}
