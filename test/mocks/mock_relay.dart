import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dart_ndk/nips/nip01/event.dart';
import 'package:dart_ndk/nips/nip01/filter.dart';
import 'package:dart_ndk/nips/nip01/key_pair.dart';
import 'package:dart_ndk/nips/nip65/nip65.dart';
import 'package:flutter_test/flutter_test.dart';

class MockRelay {
  String name;
  int? port;
  HttpServer? server;
  WebSocket? webSocket;
  Map<KeyPair, Nip65>? nip65s;
  Map<KeyPair, Nip01Event>? textNotes;

  static int startPort = 4040;

  String get url => "ws://localhost:$port";

  MockRelay({required this.name, this.nip65s}) {
    port = startPort;
    startPort++;
  }

  Future<void> startServer(
      {Map<KeyPair, Nip65>? nip65s, Map<KeyPair, Nip01Event>? textNotes}) async {
    if (nip65s != null) {
      this.nip65s = nip65s;
    }
    if (textNotes != null) {
      this.textNotes = textNotes;
    }
    await HttpServer.bind(InternetAddress.loopbackIPv4, port!).then((server) {
      this.server = server;
      server.transform(WebSocketTransformer()).listen((webSocket) {
        this.webSocket = webSocket;
        webSocket.listen((message) {
          if (message=="ping") {
            webSocket.add("pong");
            return;
          }
          var eventJson = json.decode(message);
          if (eventJson[0] == "REQ") {
            String requestId = eventJson[1];
            log('Received: $eventJson');
            Filter filter = Filter.fromMap(eventJson[2]);
            if (filter.kinds != null && filter.authors != null) {
              if (filter.kinds!.contains(Nip65.kind) && nip65s != null) {
                _respondeNip65(filter.authors!, requestId);
              }
              if (filter.kinds!.contains(Nip01Event.textNoteKind) && textNotes != null) {
                _respondeTextNote(filter.authors!, requestId);
              }
              // todo: other
            }
            List<dynamic> eose = [];
            eose.add("EOSE");
            eose.add(requestId);
            webSocket.add(jsonEncode(eose));
          }
        });
        log('Listening on localhost:${server.port}');
      });
    });
  }

  void _respondeNip65(List<String> authors, String requestId) {
    for (var author in authors) {
      KeyPair key = nip65s!.keys.where((key) => key.publicKey == author).first;
      Nip65? nip65 = nip65s![key];
      if (nip65 != null && nip65.relays.isNotEmpty) {
        List<dynamic> json = [];
        json.add("EVENT");
        json.add(requestId);

        Nip01Event event = nip65.toEvent();
        event.sign(key.privateKey!);
        json.add(event.toJson());
        webSocket!.add(jsonEncode(json));
      }
    }
  }

  void _respondeTextNote(List<String> authors, String requestId) {
    for (var author in authors) {
      List<KeyPair> keys = textNotes!.keys.where((key) => key.publicKey == author).toList();
      if (keys.isNotEmpty) {
        KeyPair key = keys.first;
        Nip01Event? textNote = textNotes![key];
        if (textNote != null) {
          List<dynamic> json = [];
          json.add("EVENT");
          json.add(requestId);

          textNote.sign(key.privateKey!);
          json.add(textNote.toJson());
          webSocket!.add(jsonEncode(json));
        }
      }
    }
  }

  Future<void> stopServer() async {
    if (server != null) {
      log('closing server on localhost:$url');
      await server!.close();
    }
  }
}
