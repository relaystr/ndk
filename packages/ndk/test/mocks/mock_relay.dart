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
  final Set<Nip01Event> _storedEvents = {}; // Store received events
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
    Duration? delayResponse,
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
      _webSocket = webSocket;
      if (requireAuthForRequests && !signedChallenge) {
        challenge = Helpers.getRandomString(10);
        webSocket.add(jsonEncode(["AUTH", challenge]));
      }
      webSocket.listen((message) async {
        if (delayResponse != null) {
          await Future.delayed(delayResponse);
        }
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
          List<Filter> filters = [];
          if (eventJson.length > 2) {
            for (int i = 2; i < eventJson.length; i++) {
              if (eventJson[i] is Map<String, dynamic>) {
                try {
                  filters.add(Filter.fromMap(eventJson[i]));
                } catch (e) {
                  log("MockRelay: Error parsing filter item in REQ: ${eventJson[i]}, error: $e");
                }
              } else {
                log("MockRelay: Malformed filter item in REQ (not a Map): ${eventJson[i]}");
              }
            }
          }
          if (filters.isNotEmpty) {
            _respondToRequest(filters, requestId);
          } else {
            // If no valid filters are provided, send EOSE immediately for this request ID
            log("MockRelay: No valid filters provided for REQ $requestId, sending EOSE.");
            _webSocket!.add(jsonEncode(["EOSE", requestId]));
          }
          return;
        }
      });
    }, onError: (error) {
      log('Error: $error');
    });

    log('Listening on localhost:${server.port}');
    myPromise.complete();

    return myPromise.future;
  }

  void _respondToRequest(List<Filter> filters, String requestId) {
    Set<Nip01Event> allMatchingEvents = {};

    for (Filter filter in filters) {
      List<Nip01Event> eventsForThisFilter = [];

      // Match against contact lists
      if (filter.kinds != null &&
          filter.kinds!.contains(ContactList.kKind) &&
          filter.authors != null &&
          filter.authors!.isNotEmpty) {
        eventsForThisFilter.addAll(_contactLists.values
            .where((e) => filter.authors!.contains(e.pubKey))
            .toList());
      }
      // Match against metadatas
      else if (filter.kinds != null &&
          filter.kinds!.contains(Metadata.kKind) &&
          filter.authors != null &&
          filter.authors!.isNotEmpty) {
        eventsForThisFilter.addAll(_metadatas.values
            .where((e) => filter.authors!.contains(e.pubKey))
            .toList());
      }
      // General event matching (storedEvents and textNotes)
      else {
        eventsForThisFilter.addAll(_storedEvents.where((event) {
          bool kindMatches =
              filter.kinds == null || filter.kinds!.contains(event.kind);
          bool authorMatches =
              filter.authors == null || filter.authors!.contains(event.pubKey);
          bool idsMatches =
              filter.ids == null || filter.ids!.contains(event.id);
          // Add other tag-based filtering if necessary, e.g., #e, #p tags
          return kindMatches && authorMatches && idsMatches;
        }).toList());

        if (textNotes != null) {
          eventsForThisFilter.addAll(textNotes!.values.where((event) {
            bool kindMatches =
                filter.kinds == null || filter.kinds!.contains(event.kind);
            bool authorMatches = filter.authors == null ||
                filter.authors!.contains(event.pubKey);
            bool idsMatches =
                filter.ids == null || filter.ids!.contains(event.id);
            // Add other tag-based filtering if necessary
            return kindMatches && authorMatches && idsMatches;
          }).toList());
        }
      }

      // Match against NIP-65s
      if (_nip65s != null) {
        for (var entry in _nip65s!.entries) {
          if (filter.authors != null &&
              filter.authors!.contains(entry.key.publicKey) &&
              (filter.kinds == null || filter.kinds!.contains(Nip65.kKind))) {
            Nip01Event eventToAdd =
                entry.value.toEvent(); // Creates a new event instance
            if (signEvents && entry.key.privateKey != null) {
              // Sign the new instance, not the one in _nip65s
              eventToAdd.sign(entry.key.privateKey!);
            }
            eventsForThisFilter.add(eventToAdd);
          }
        }
      }

      // Match against textNotes (again, for specific kinds if not covered by general else)
      // This block might be redundant if general matching for textNotes is sufficient
      // or could be more specific if textNotes have unique matching criteria.
      // For now, ensuring signing is handled correctly if events are matched here.
      if (textNotes != null) {
        for (final entry in textNotes!.entries) {
          bool authorsMatch = filter.authors != null &&
              filter.authors!.contains(entry.key.publicKey);
          bool kindsMatch = filter.kinds == null ||
              filter.kinds!.contains(entry.value.kind) ||
              (entry.value.kind == Nip01Event.kTextNodeKind &&
                  filter.kinds!.contains(Nip01Event.kTextNodeKind)) ||
              (filter.kinds!.any((k) =>
                  Nip51List.kPossibleKinds.contains(k) &&
                  Nip51List.kPossibleKinds.contains(entry.value.kind)));

          if (authorsMatch && kindsMatch) {
            // Clone the event from the map before signing to avoid mutating the stored original
            Nip01Event eventToAdd = Nip01Event.fromJson(entry.value.toJson());
            if (signEvents && entry.key.privateKey != null) {
              eventToAdd.sign(entry.key.privateKey!);
            }
            eventsForThisFilter.add(eventToAdd);
          }
        }
      }
      allMatchingEvents.addAll(eventsForThisFilter);
    }

    for (var event in allMatchingEvents) {
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
