import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:bip340/bip340.dart';
import 'package:ndk/domain_layer/usecases/bunkers/models/bunker_request.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/helpers.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:ndk/shared/nips/nip09/deletion.dart';
import 'package:ndk/shared/nips/nip04/nip04.dart';
import 'package:ndk/shared/nips/nip44/nip44.dart';

class MockRelay {
  String name;
  int? _port;
  HttpServer? server;
  Map<KeyPair, Nip65>? _nip65s;
  Map<KeyPair, Nip01Event>? textNotes;
  Map<String, Nip01Event> _contactLists = {};
  Map<String, Nip01Event> _metadatas = {};
  final Set<Nip01Event> _storedEvents = {}; // Store received events

  // Track all connected clients with their subscriptions
  final Map<WebSocket, Map<String, List<Filter>>> _clientSubscriptions = {};
  bool signEvents;
  bool requireAuthForRequests;
  bool requireAuthForEvents;
  bool sendAuthChallenge;
  bool allwaysSendBadJson;
  bool sendMalformedEvents;
  String? customWelcomeMessage;
  String? bannedWord;

  // NIP-46 Remote Signer Support
  static const int kNip46Kind = BunkerRequest.kKind;

  // Hardcoded remote signer keys
  static const String _remoteSignerPrivateKey =
      "e7158a4379e743889f8ea8cfcdf4bd904cdfde4ff8a1c545aad4590d8a3acccc";
  static const String remoteSignerPublicKey =
      "52f58988d7aaea17936581db7ff19074633557fad37f354323cea579b1025cef";

  static int _startPort = 4040;

  String get url => "ws://localhost:$_port";

  MockRelay({
    required this.name,
    Map<KeyPair, Nip65>? nip65s,
    this.signEvents = true,
    this.requireAuthForRequests = false,
    this.requireAuthForEvents = false,
    this.sendAuthChallenge = true,
    this.allwaysSendBadJson = false,
    this.sendMalformedEvents = false,
    this.customWelcomeMessage,
    this.bannedWord,
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
    Set<String> authenticatedPubkeys = {};

    stream.listen((webSocket) {
      // Register this client
      _clientSubscriptions[webSocket] = {};

      if (customWelcomeMessage != null) {
        webSocket.add(customWelcomeMessage!);
      }
      if ((requireAuthForRequests || requireAuthForEvents) &&
          sendAuthChallenge) {
        challenge = Helpers.getRandomString(10);
        webSocket.add(jsonEncode(["AUTH", challenge]));
      }
      webSocket.listen((message) async {
        if (allwaysSendBadJson) {
          webSocket.add('{"bad_json":,}');
          return;
        }
        if (delayResponse != null) {
          await Future.delayed(delayResponse);
        }
        if (message == "ping") {
          webSocket.add("pong");
          return;
        }
        var eventJson = json.decode(message);

        if (eventJson[0] == "AUTH") {
          Nip01Event event = Nip01EventModel.fromJson(eventJson[1]);
          bool authSuccess = false;
          if (verify(event.pubKey, event.id, event.sig!)) {
            String? relay = event.getFirstTag("relay");
            String? eventChallenge = event.getFirstTag("challenge");
            if (eventChallenge == challenge && relay == url) {
              authenticatedPubkeys.add(event.pubKey);
              authSuccess = true;
            }
          }

          webSocket.add(jsonEncode([
            "OK",
            event.id,
            authSuccess,
            authSuccess ? "" : "auth-required: authentication failed"
          ]));
          return;
        }
        if (eventJson[0] == "EVENT") {
          Nip01Event newEvent = Nip01EventModel.fromJson(eventJson[1]);
          if (verify(newEvent.pubKey, newEvent.id, newEvent.sig!)) {
            // Check if event contains banned word
            if (bannedWord != null && newEvent.content.contains(bannedWord!)) {
              webSocket.add(jsonEncode([
                "OK",
                newEvent.id,
                false,
                "blocked: content contains banned word"
              ]));
              return;
            }
            // Check auth for events if required (any authenticated user is OK)
            if (requireAuthForEvents && authenticatedPubkeys.isEmpty) {
              webSocket.add(jsonEncode([
                "OK",
                newEvent.id,
                false,
                "auth-required: we only accept events from authenticated users"
              ]));
              return;
            }
            if (newEvent.kind == ContactList.kKind) {
              _contactLists[newEvent.pubKey] = newEvent;
            } else if (newEvent.kind == Metadata.kKind) {
              _metadatas[newEvent.pubKey] = newEvent;
            } else if (newEvent.kind == Deletion.kKind) {
              final eventIdsToDelete = newEvent.getTags("e");
              for (final idToDelete in eventIdsToDelete) {
                _storedEvents.removeWhere((e) => idToDelete == e.id);
                // remove from textNotes map
                if (textNotes != null) {
                  textNotes.removeWhere((key, event) => event.id == idToDelete);
                }
                //remove from contact lists and metadata
                _contactLists
                    .removeWhere((key, event) => event.id == idToDelete);
                _metadatas.removeWhere((key, event) => event.id == idToDelete);
              }
            } else if (_isEphemeralKind(newEvent.kind)) {
              // Ephemeral events (kinds 20000-29999) are broadcast but NOT stored
              _broadcastEventToSubscriptions(newEvent);
              // Also handle NIP-46 if targeting our mock signer
              if (newEvent.kind == kNip46Kind) {
                _handleNip46Request(newEvent, webSocket);
              }
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

          // Check auth: any authenticated user can access all data
          if (requireAuthForRequests && authenticatedPubkeys.isEmpty) {
            webSocket.add(jsonEncode([
              "CLOSED",
              requestId,
              "auth-required: we can't serve requests to unauthenticated users"
            ]));
            return;
          }

          if (filters.isNotEmpty) {
            // Store the subscription for this client
            _clientSubscriptions[webSocket]?[requestId] = filters;
            _respondToRequest(webSocket, filters, requestId);
          } else {
            // If no valid filters are provided, send EOSE immediately for this request ID
            log("MockRelay: No valid filters provided for REQ $requestId, sending EOSE.");
            webSocket.add(jsonEncode(["EOSE", requestId]));
          }
          return;
        }

        if (eventJson[0] == "CLOSE") {
          String subscriptionId = eventJson[1];
          // Remove the subscription for this client
          if (_clientSubscriptions[webSocket]?.containsKey(subscriptionId) ??
              false) {
            _clientSubscriptions[webSocket]?.remove(subscriptionId);
            log("MockRelay: Closed subscription $subscriptionId");
          } else {
            log("MockRelay: Attempted to close non-existent subscription $subscriptionId");
          }
          return;
        }
      }, onDone: () {
        // Clean up when client disconnects
        _clientSubscriptions.remove(webSocket);
        log("MockRelay: Client disconnected");
      });
    }, onError: (error) {
      log('Error: $error');
    });

    log('Listening on localhost:${server.port}');
    myPromise.complete();

    return myPromise.future;
  }

  void _respondToRequest(
      WebSocket webSocket, List<Filter> filters, String requestId) {
    if (sendMalformedEvents) {
      final malformedEventJson =
          '["EVENT", "$requestId", {"id":null,"pubkey":null,"created_at":${DateTime.now().millisecondsSinceEpoch ~/ 1000},"kind":0,"tags":[],"content":null,"sig":null}]';
      webSocket.add(malformedEventJson);
      webSocket.add(jsonEncode(["EOSE", requestId]));
      return;
    }

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
            final Nip01Event? eventToAddSigned;
            if (signEvents && entry.key.privateKey != null) {
              // Sign the new instance, not the one in _nip65s

              eventToAddSigned = Nip01Utils.signWithPrivateKey(
                  event: eventToAdd, privateKey: entry.key.privateKey!);
            } else {
              eventToAddSigned = null;
            }

            eventsForThisFilter.add(eventToAddSigned ?? eventToAdd);
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
            Nip01Event eventToAdd = entry.value.copyWith();
            Nip01Event? eventToAddSigned;
            if (signEvents && entry.key.privateKey != null) {
              eventToAddSigned = Nip01Utils.signWithPrivateKey(
                  event: eventToAdd, privateKey: entry.key.privateKey!);
            } else {
              eventToAddSigned = null;
            }
            eventsForThisFilter.add(eventToAddSigned ?? eventToAdd);
          }
        }
      }
      allMatchingEvents.addAll(eventsForThisFilter);
    }

    for (final event in allMatchingEvents) {
      webSocket.add(jsonEncode(
          ["EVENT", requestId, Nip01EventModel.fromEntity(event).toJson()]));
    }

    webSocket.add(jsonEncode(["EOSE", requestId]));
  }

  /// Sends event to all connected clients
  /// If key pair is provided, it will sign the event
  void sendEvent({
    required Nip01Event event,
    required String subId,
    KeyPair? keyPair,
  }) {
    if (_clientSubscriptions.isEmpty) {
      throw Exception("No clients connected");
    }

    Nip01Event? signedEvent;
    if (keyPair != null) {
      signedEvent = Nip01Utils.signWithPrivateKey(
          event: event, privateKey: keyPair.privateKey!);
    }

    final eventToSend = signedEvent ?? event;
    final eventToSendModel = Nip01EventModel.fromEntity(eventToSend);

    // Send to all connected clients
    for (var clientSocket in _clientSubscriptions.keys) {
      clientSocket.add(jsonEncode(["EVENT", subId, eventToSendModel.toJson()]));
    }
  }

  /// Sends a CLOSED message to all connected clients
  void sendClosed(String subId, {String message = ""}) {
    // Send to all connected clients
    for (var clientSocket in _clientSubscriptions.keys) {
      clientSocket.add(jsonEncode(["CLOSED", subId, message]));
    }
  }

  /// Check if a kind is ephemeral (20000-29999) per NIP-01
  bool _isEphemeralKind(int kind) {
    return kind >= 20000 && kind < 30000;
  }

  /// Broadcast an event to all clients with matching subscriptions
  void _broadcastEventToSubscriptions(Nip01Event event) {
    for (var clientEntry in _clientSubscriptions.entries) {
      final clientSocket = clientEntry.key;
      final subscriptions = clientEntry.value;

      for (var subEntry in subscriptions.entries) {
        final subscriptionId = subEntry.key;
        final filters = subEntry.value;

        for (var filter in filters) {
          if (_eventMatchesFilter(event, filter)) {
            clientSocket.add(jsonEncode([
              "EVENT",
              subscriptionId,
              Nip01EventModel.fromEntity(event).toJson()
            ]));
            break; // Only send once per subscription
          }
        }
      }
    }
  }

  /// Check if an event matches a filter
  bool _eventMatchesFilter(Nip01Event event, Filter filter) {
    // Check kinds filter
    if (filter.kinds != null && !filter.kinds!.contains(event.kind)) {
      return false;
    }

    // Check authors filter
    if (filter.authors != null && !filter.authors!.contains(event.pubKey)) {
      return false;
    }

    // Check ids filter
    if (filter.ids != null && !filter.ids!.contains(event.id)) {
      return false;
    }

    // Check #p tag filter
    if (filter.pTags != null) {
      List<String> eventPTags = event.tags
          .where((tag) => tag.isNotEmpty && tag[0] == 'p')
          .map((tag) => tag[1])
          .toList();
      if (!filter.pTags!.any((pTag) => eventPTags.contains(pTag))) {
        return false;
      }
    }

    // Check #e tag filter
    if (filter.eTags != null) {
      List<String> eventETags = event.tags
          .where((tag) => tag.isNotEmpty && tag[0] == 'e')
          .map((tag) => tag[1])
          .toList();
      if (!filter.eTags!.any((eTag) => eventETags.contains(eTag))) {
        return false;
      }
    }

    return true;
  }

  Future<void> stopServer() async {
    if (server != null) {
      log('Closing server on localhost:$url');
      await server!.close();
    }
  }

  /// Handle NIP-46 remote signer requests
  void _handleNip46Request(Nip01Event event, WebSocket webSocket) async {
    try {
      // Get the 'p' tag which contains the remote signer's public key
      String? targetPubkey = event.getFirstTag('p');
      if (targetPubkey != remoteSignerPublicKey) {
        // This request is not for our remote signer
        return;
      }

      // Decrypt the content using NIP-44 (as per NIP-46 spec)
      String decryptedContent;
      try {
        decryptedContent = await Nip44.decryptMessage(
            event.content, _remoteSignerPrivateKey, event.pubKey);
      } catch (e) {
        log('MockRelay: Failed to decrypt NIP-46 request: $e');
        return;
      }

      // Parse the JSON request
      Map<String, dynamic> request = jsonDecode(decryptedContent);
      String? id = request['id'];
      String? method = request['method'];
      List<dynamic>? params = request['params'];

      if (id == null || method == null) {
        log('MockRelay: Invalid NIP-46 request format');
        return;
      }

      // Process the request and generate response
      Map<String, dynamic> response = await _processNip46Method(method, params);
      response['id'] = id;

      // Create response event
      String responseContent = jsonEncode(response);
      String encryptedResponse;
      try {
        encryptedResponse = await Nip44.encryptMessage(
            responseContent, _remoteSignerPrivateKey, event.pubKey);
      } catch (e) {
        log('MockRelay: Failed to encrypt NIP-46 response: $e');
        return;
      }

      // Create NIP-46 response event
      Nip01Event responseEventUnsinged = Nip01Event(
        pubKey: remoteSignerPublicKey,
        kind: kNip46Kind,
        tags: [
          ['p', event.pubKey], // Tag the requester
        ],
        content: encryptedResponse,
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
      Nip01Event responseEvent = Nip01Utils.signWithPrivateKey(
          event: responseEventUnsinged, privateKey: _remoteSignerPrivateKey);

      // NIP-46 events are ephemeral (kind 24133), broadcast to matching subscriptions
      _broadcastEventToSubscriptions(responseEvent);
    } catch (e) {
      log('MockRelay: Error handling NIP-46 request: $e');
    }
  }

  /// Process NIP-46 methods
  Future<Map<String, dynamic>> _processNip46Method(
      String method, List<dynamic>? params) async {
    try {
      switch (method) {
        case 'connect':
          // Handle connection request with optional secret
          if (params != null && params.isNotEmpty) {
            // In a real implementation, you'd validate the secret here
            String? secret = params[0];
            log('MockRelay: NIP-46 connect with secret: ${secret != null}');
          }
          return {
            'result': 'ack',
          };

        case 'ping':
          return {
            'result': 'pong',
          };

        case 'get_relays':
          // Return the relay URL where this signer is available
          return {
            'result': {
              url: {'read': true, 'write': true},
            },
          };

        case 'disconnect':
          // Handle disconnection
          return {
            'result': 'ack',
          };

        case 'get_public_key':
          return {
            'result': remoteSignerPublicKey,
          };

        case 'sign_event':
          if (params == null || params.isEmpty) {
            return {'error': 'Missing event parameter'};
          }

          // NIP-46 sends the event as a JSON string in params[0]
          Map<String, dynamic> eventData;
          if (params[0] is String) {
            eventData = jsonDecode(params[0]);
          } else {
            eventData = params[0];
          }

          // Use the Nip01Event constructor directly
          final Nip01Event eventToSign = Nip01Event(
            pubKey: remoteSignerPublicKey,
            kind: eventData["kind"] ?? 1,
            tags: List<List<String>>.from(eventData["tags"] ?? []),
            content: eventData["content"] ?? "",
            createdAt: eventData["created_at"] ?? eventData["createdAt"] ?? 0,
          );

          final Nip01Event signedEvent = Nip01Utils.signWithPrivateKey(
              event: eventToSign, privateKey: _remoteSignerPrivateKey);

          return {
            'result': Nip01EventModel.fromEntity(signedEvent).toJsonString(),
          };

        case 'nip04_encrypt':
          if (params == null || params.length < 2) {
            return {'error': 'Missing parameters for nip04_encrypt'};
          }

          String pubkey = params[0];
          String plaintext = params[1];
          String encrypted =
              Nip04.encrypt(_remoteSignerPrivateKey, pubkey, plaintext);

          return {
            'result': encrypted,
          };

        case 'nip04_decrypt':
          if (params == null || params.length < 2) {
            return {'error': 'Missing parameters for nip04_decrypt'};
          }

          String pubkey = params[0];
          String ciphertext = params[1];
          String decrypted =
              Nip04.decrypt(_remoteSignerPrivateKey, pubkey, ciphertext);

          return {
            'result': decrypted,
          };

        case 'nip44_encrypt':
          if (params == null || params.length < 2) {
            return {'error': 'Missing parameters for nip44_encrypt'};
          }

          String pubkey = params[0];
          String plaintext = params[1];
          String encrypted = await Nip44.encryptMessage(
              plaintext, _remoteSignerPrivateKey, pubkey);

          return {
            'result': encrypted,
          };

        case 'nip44_decrypt':
          if (params == null || params.length < 2) {
            return {'error': 'Missing parameters for nip44_decrypt'};
          }

          String pubkey = params[0];
          String ciphertext = params[1];
          String decrypted = await Nip44.decryptMessage(
              ciphertext, _remoteSignerPrivateKey, pubkey);

          return {
            'result': decrypted,
          };

        default:
          return {
            'error': 'Unknown method: $method',
          };
      }
    } catch (e) {
      return {
        'error': 'Error processing method $method: $e',
      };
    }
  }
}
