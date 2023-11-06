import 'dart:async';

import 'package:dart_ndk/dart_ndk.dart';
import 'package:dart_ndk/nips/nip01/event.dart';
import 'package:dart_ndk/nips/nip01/event_verifier.dart';

import 'nips/nip01/filter.dart';

class RelayRequest {
  String url;
  List<Filter> filters;

  RelayRequest(this.url, this.filters);
}

// Requests made to several relays, identified by same id
class NostrRequest {
  String id;
  EventVerifier eventVerifier;

  Map<String, RelayRequest> requests = {};

  StreamController<Nip01Event> controller = StreamController<Nip01Event>();
  bool closeOnEOSE;
  int? groupIdleTimeout;
  bool shouldClose=false;
  Function(NostrRequest)? onTimeout;

  Stream<Nip01Event> get stream => groupIdleTimeout != null
      ? _stream().timeout(Duration(seconds: groupIdleTimeout!), onTimeout: (sink) {
          if (onTimeout != null) {
            onTimeout!.call(this);
          }
        })
      : _stream();

  Stream<Nip01Event> _stream() {
    return controller.stream.transform(StreamTransformer.fromHandlers(handleData: (data, sink) async {
      // sink.add(data);
      eventVerifier.verify(data).then((value) {
            if (value) {
              try {
                sink.add(data);
                if (shouldClose) {
                  controller.close();
                }
              } catch (e) {
                print(e);
              }
            }
          });
    }));
  }

  NostrRequest.query(
    this.id, {
    this.closeOnEOSE = true,
    required this.eventVerifier,
    this.groupIdleTimeout = RelayManager.DEFAULT_STREAM_IDLE_TIMEOUT + 1,
    this.onTimeout,
  });

  NostrRequest.subscription(this.id, {this.closeOnEOSE = false, required this.eventVerifier});

  void addRequest(String url, List<Filter> filters) {
    if (!requests.containsKey(url)) {
      requests[url] = RelayRequest(url, filters);
    }
  }
}
