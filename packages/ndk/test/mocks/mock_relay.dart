import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:bip340/bip340.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/shared/nips/nip01/helpers.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:ndk/shared/nips/nip09/deletion.dart';

class MockRelay {
  String name;
  int? _port;
  HttpServer? server;
  WebSocket? _webSocket;
  Map<KeyPair, Nip65>? _nip65s;
  Map<KeyPair, Nip01Event>? textNotes;
  Map<String, Nip01Event> _contactLists = {};
  Map<String, Nip01Event> _metadatas = {};
  List<Nip01Event> _storedEvents = []; // Store received events
  bool signEvents;
  bool requireAuthForRequests;

  static int _startPort = 4040;

  String get url => "ws://localhost:$_port";

  MockRelay({
    required this.name,
    Map<KeyPair, Nip65>? nip65s,
    this.signEvents = true,
    this.requireAuthForRequests = false,
    int? explicitPort,
  }) : _nip65s = nip65s {
    if (explicitPort != null) {
      _port = explicitPort;
    } else {
      _port = _startPort;
      _startPort++;
    }
  }

  Future<void> startServer({
    Map<KeyPair, Nip65>? nip65s,
    Map<KeyPair, Nip01Event>? textNotes,
    Map<String, Nip01Event>? contactLists,
    Map<String, Nip01Event>? metadatas,
  }) async {
    var myPromise = Completer<void>();

    if (nip65s != null) {
      _nip65s = nip65s;
    }
    if (textNotes != null) {
      this.textNotes = textNotes;
    }
    if (contactLists != null) {
      _contactLists = contactLists;
    }
    if (metadatas != null) {
      _metadatas = metadatas;
    }

    var server = await HttpServer.bind(InternetAddress.loopbackIPv4, _port!,
        shared: true);
    this.server = server;
    var stream = server.transform(WebSocketTransformer());

    String challenge = '';
    bool signedChallenge = false;

    stream.listen((webSocket) {
      this._webSocket = webSocket;
      if (requireAuthForRequests && !signedChallenge) {
        challenge = Helpers.getRandomString(10);
        webSocket.add(jsonEncode(["AUTH", challenge]));
      }
      webSocket.listen((message) {
        if (message == "ping") {
          webSocket.add("pong");
          return;
        }
        var eventJson = json.decode(message);

        if (eventJson[0] == "AUTH") {
          Nip01Event event = Nip01Event.fromJson(eventJson[1]);
          if (verify(event.pubKey, event.id, event.sig)) {
            String? relay = event.getFirstTag("relay");
            String? eventChallenge = event.getFirstTag("challenge");
            if (eventChallenge == challenge && relay == url) {
              signedChallenge = true;
            }
          }
          webSocket.add(jsonEncode([
            "OK",
            event.id,
            signedChallenge,
            signedChallenge ? "" : "auth-required"
          ]));
          return;
        }
        if (requireAuthForRequests && !signedChallenge) {
          webSocket.add(jsonEncode([
            "CLOSED",
            "sub_1",
            "auth-required: we can't serve requests to unauthenticated users"
          ]));
          return;
        }

        if (eventJson[0] == "EVENT") {
          Nip01Event newEvent = Nip01Event.fromJson(eventJson[1]);
          if (verify(newEvent.pubKey, newEvent.id, newEvent.sig)) {
            if (newEvent.kind == ContactList.kKind) {
              _contactLists[newEvent.pubKey] = newEvent;
            } else if (newEvent.kind == Metadata.kKind) {
              _metadatas[newEvent.pubKey] = newEvent;
            } else if (newEvent.kind == Deletion.kKind) {
              // TODO: should handle more kinds (nip65, metadatas, contact lists, etc)
              _storedEvents.removeWhere((e) => newEvent.getEId() == e.id);
            } else {
              _storedEvents.add(newEvent);
            }
            webSocket.add(jsonEncode(["OK", newEvent.id, true, ""]));
          } else {
            webSocket.add(
                jsonEncode(["OK", newEvent.id, false, "invalid signature"]));
          }
          return;
        }

        if (eventJson[0] == "REQ") {
          String requestId = eventJson[1];
          Filter filter = Filter.fromMap(eventJson[2]);
          _respondToRequest(filter, requestId);
        }
      });
    }, onError: (error) {
      log('Error: $error');
    });

    log('Listening on localhost:${server.port}');
    myPromise.complete();

    return myPromise.future;
  }

  void _respondToRequest(Filter filter, String requestId) {
    List<Nip01Event> matchingEvents = [];
    if (filter.kinds != null &&
        filter.kinds!.contains(ContactList.kKind) &&
        filter.authors != null &&
        filter.authors!.isNotEmpty) {
      matchingEvents = _contactLists.values
          .where((e) => filter.authors!.contains(e.pubKey))
          .toList();
    } else if (filter.kinds != null &&
        filter.kinds!.contains(Metadata.kKind) &&
        filter.authors != null &&
        filter.authors!.isNotEmpty) {
      matchingEvents = _metadatas.values
          .where((e) => filter.authors!.contains(e.pubKey))
          .toList();
    } else {
      matchingEvents = _storedEvents.where((event) {
        bool kindMatches =
            filter.kinds == null || filter.kinds!.contains(event.kind);
        bool authorMatches =
            filter.authors == null || filter.authors!.contains(event.pubKey);
        return kindMatches && authorMatches;
      }).toList();

    }
    if (_nip65s != null) {
      for (var entry in _nip65s!.entries) {
        if (filter.authors != null &&
            filter.authors!.contains(entry.key.publicKey) &&
            (filter.kinds == null || filter.kinds!.contains(Nip65.kKind))) {
          if (signEvents) {
            Nip01Event event = entry.value.toEvent();
            event.sign(entry.key.privateKey!);
          }
          matchingEvents.add(entry.value.toEvent());
        }
      }
    }

    if (textNotes != null) {
      for (var entry in textNotes!.entries) {
        if (filter.authors != null &&
            filter.authors!.contains(entry.key.publicKey) &&
            (filter.kinds == null ||
                filter.kinds!.contains(Nip01Event.kTextNodeKind) ||
                filter.kinds!
                    .any((k) => Nip51List.kPossibleKinds.contains(k)))) {
          if (signEvents) {
            entry.value.sign(entry.key.privateKey!);
          }
          matchingEvents.add(entry.value);
        }
      }
    }
    for (var event in matchingEvents) {
      _webSocket!.add(jsonEncode(["EVENT", requestId, event.toJson()]));
    }

    _webSocket!.add(jsonEncode(["EOSE", requestId]));
  }

  Future<void> stopServer() async {
    if (server != null) {
      log('Closing server on localhost:$url');
      await server!.close();
    }
  }
}
