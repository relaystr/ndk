import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:developer';

import 'package:dart_ndk/bip340.dart';
import 'package:dart_ndk/nips/nip01.dart';
import 'package:dart_ndk/filter.dart';
import 'package:dart_ndk/nips/nip65.dart';
import 'package:flutter_test/flutter_test.dart';

class MockRelay {
  int? port;
  HttpServer? server;
  WebSocket? webSocket;
  Map<KeyPair, Nip65>? nip65s;
  int? nip65CreatedAt;

  static int startPort = 4040;

  String get url => "ws://localhost:$port";

  MockRelay({this.nip65s}) {
    port = startPort;
    startPort++;
  }

  Future<void> startServer(
      {Map<KeyPair, Nip65>? nip65s, int? nip65CreatedAt}) async {
    if (nip65s != null) {
      this.nip65s = nip65s;
      this.nip65CreatedAt = nip65CreatedAt;
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
      Nip65? nip65 = nip65s![key];
      if (nip65 != null && nip65.relays.isNotEmpty) {
        List<dynamic> json = [];
        json.add("EVENT");
        json.add(id);

        Nip01Event event = nip65.toEvent(key.publicKey);
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
