import 'dart:async';

import 'package:dart_ndk/dart_ndk.dart';

import 'ndk_request.dart';

class RequestResponse {
  final Stream<Nip01Event> stream;

  //! not sure if we can always inject a stream
  RequestResponse(this.stream);
}
