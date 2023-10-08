import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:developer';

import 'package:dart_ndk/bip340.dart';
import 'package:dart_ndk/event.dart';
import 'package:dart_ndk/filter.dart';
import 'package:dart_ndk/nips/Nip65.dart';
import 'package:flutter_test/flutter_test.dart';

class MockRelay {
  int? port;
  HttpServer? server;
  WebSocket? webSocket;
  Map<KeyPair, Set<String>>? nip65s;

  static int startPort = 4040;

  String get url => "ws://localhost:$port";

  MockRelay({this.nip65s}) {
    port = startPort;
    startPort++;
  }

  Future<void> startServer({Map<KeyPair, Set<String>>? nip65s}) async {
    if (nip65s != null) {
      this.nip65s = nip65s;
    }
    await HttpServer.bind(InternetAddress.loopbackIPv4, port!).then((server) {
      this.server = server;
      server.transform(WebSocketTransformer()).listen((webSocket) {
        this.webSocket = webSocket;
        webSocket.listen((message) {
          var eventJson = json.decode(message);
          if (eventJson[0] == "REQ") {
            String id = eventJson[1];
            log('Received: $eventJson');
            Filter filter = Filter.fromJson(eventJson[2]);
            if (filter.kinds != null) {
              if (filter.kinds!.contains(Nip65.kind) &&
                  nip65s != null &&
                  filter.authors != null) {
                _respondeNip65(filter.authors!, id);
              }
              // todo: other
            }
          }
        });
        log('Listening on localhost:${server.port}');
      });
    });
  }

  void _respondeNip65(List<String> authors, String id) {
    authors.forEach((author) {

      KeyPair key = nip65s!.keys.where((key) => key.publicKey == author).first;
      Set<String>? relays = nip65s![key];
      if (relays != null) {
        List<dynamic> json = [];
        json.add("EVENT");
        json.add(id);

        Event event = Event(author, Nip65.kind, relays.map((relay) => ["r", relay]).toList(), "");
        event.sign(key.privateKey!);
        json.add(event.toJson());
        webSocket!.add(jsonEncode(json));
      }
    });
  }

  Future<void> stopServer() async {
    if (server != null) {
      log('closing server on localhost:${url}');
      await server!.close();
    }
  }
}
