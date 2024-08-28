import 'dart:async';

import 'nip_01_event.dart';

class NdkResponse {
  String requestId;
  final Stream<Nip01Event> stream;

  //! not sure if we can always inject a stream
  NdkResponse(this.requestId, this.stream);
}
