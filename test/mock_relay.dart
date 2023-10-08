import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_ndk/filter.dart';
import 'package:dart_ndk/nips/Nip65.dart';
import 'package:flutter_test/flutter_test.dart';

class MockRelay {
  int? port;
  HttpServer? server;
  Map<String, Set<String>>? nip65s;

  static int startPort = 4040;

//  ["EVENT","asev0xmtdzw51mh5",{"content":"","created_at":1696425535,"id":"bc2752d303195c9cd8f8f989f615da5d4a1bb52a18ee9a63718d0efab3de6986","kind":10002,
//  "pubkey":"30782a8323b7c98b172c5a2af7206bb8283c655be6ddce11133611a03d5f1177",
//  "sig":"6e52f097108b4c3d29fdf7719ac7eee48d39c2c2192999fe05bb0dc6504b569ff9352a54dabff873b2e20e30762bcdb130f60c48174db754e9d2b4dd23962ee4",
//  "tags":[["r","wss://nostr.filmweb.pl",""],["r","wss://relay.dwadziesciajeden.pl",""],["r","wss://relay.snort.social/",""],["r","wss://nos.lol",""],["r","wss://relay.damus.io",""],["r","wss://purplepag.es",""],["r","wss://nostr.wine",""],["r","wss://relay.nostr.band",""]]}]

  String get url => "ws://localhost:$port";

  MockRelay( {this.nip65s}){
    port = startPort;
    startPort++;
  }

  var webSocketTransformer = WebSocketTransformer();

  Future<void> startServer( {Map<String, Set<String>>? nip65s}) async {
    if (nip65s!=null) {
      this.nip65s = nip65s;
    }
    await HttpServer.bind(InternetAddress.loopbackIPv4, port!).then((server) {
      this.server = server;
      server.transform(webSocketTransformer).listen((webSocket) {
        webSocket.listen((message) {
          var eventJson = json.decode(message);
          if (eventJson[0] == "REQ") {
            String id = eventJson[1];
            print('Received: $eventJson');
            Filter filter = Filter.fromJson(eventJson[2]);
            if (filter.kinds != null &&
                filter.kinds!.contains(Nip65.kind) &&
                nip65s != null &&
                filter.authors != null) {
              filter.authors!.forEach((author) {
                Set<String>? relays = nip65s![author];
                if (relays != null) {
                  List<dynamic> event = [];
                  event.add("EVENT");
                  event.add(id);
                  Map<String, dynamic> map = {};
                  map["kind"] = Nip65.kind;
                  map["pubkey"] = author;
                  map["created_at"] = DateTime.now().millisecondsSinceEpoch;
                  map["tags"] = relays.map((relay) => ["r", relay]).toList();
                  map["id"] = "TODO";
                  map["sig"] = "TODO";
                  event.add(map);
                  webSocket.add(jsonEncode(event));
                }
              });
            }
          }
        });
      });
      print('Listening on localhost:${server.port}');
    });
  }

  Future<void> stopServer() async {
    if (server != null) {
      print('closing server on localhost:${server!.port}');
      await server!.close();
    }
  }
}
