import 'dart:async';

import 'package:async/async.dart' show StreamGroup;
import 'package:dart_ndk/dart_ndk.dart';
import 'package:dart_ndk/nips/nip01/event.dart';

import 'nips/nip01/filter.dart';

class RelayRequest {
  String url;
  List<Filter> filters;
  StreamController<Nip01Event>? controller;

  RelayRequest(this.url, this.filters);
}

// Requests made to several relays, identified by same id
class NostrRequest {
  String id;

  Map<String, RelayRequest> requests = {};

  StreamGroup<Nip01Event> streamGroup = StreamGroup<Nip01Event>();
  bool closeOnEOSE;
  int? idleTimeout;
  int? groupIdleTimeout;
  Function(Nip01Event)? onEvent;
  Function(NostrRequest)? onTimeout;

  Stream<Nip01Event> get stream => groupIdleTimeout != null ? streamGroup.stream.timeout(Duration(seconds: groupIdleTimeout!), onTimeout: (sink) {
    if (onTimeout!=null) {
      onTimeout!.call(this);
    }
  }) : streamGroup.stream;

  NostrRequest.query(this.id,
      {this.closeOnEOSE = true,
      this.idleTimeout = RelayManager.DEFAULT_STREAM_IDLE_TIMEOUT,
      this.groupIdleTimeout = RelayManager.DEFAULT_STREAM_IDLE_TIMEOUT + 1,
      this.onTimeout,
      this.onEvent
      });

  NostrRequest.subscription(this.id, {this.closeOnEOSE = false});

  void addRequest(String url, List<Filter> filters) {
    if (!requests.containsKey(url)) {
      requests[url] = RelayRequest(url, filters);
      requests[url]!.controller = StreamController<Nip01Event>();
      Stream<Nip01Event> singleStream = requests[url]!.controller!.stream;
      if (idleTimeout != null) {
        singleStream = singleStream.timeout(Duration(seconds: idleTimeout!), onTimeout: (sink) {
          // print("TIMED OUT on relay $url for ${jsonEncode(filter.toMap())}");
          print("$idleTimeout TIMED OUT on relay $url for kinds ${requests[url]!.filters.first.kinds}");
          sink.close();
        });
      }
      streamGroup.add(singleStream);
    }
  }
}
