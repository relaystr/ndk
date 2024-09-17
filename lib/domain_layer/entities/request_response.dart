import 'dart:async';

import 'nip_01_event.dart';

class NdkResponse {
  String requestId;
  final Stream<Nip01Event> stream;

  /// waits until request is complete and returns a list
  Future<List<Nip01Event>> get future => stream.toList();

  NdkResponse(this.requestId, this.stream);
}
