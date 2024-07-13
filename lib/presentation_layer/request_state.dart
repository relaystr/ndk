import 'dart:async';

import 'package:dart_ndk/domain_layer/entities/nip_01_event.dart';
import 'package:dart_ndk/presentation_layer/ndk_request.dart';

class RequestState {
  StreamController<Nip01Event> controller = StreamController<Nip01Event>();

  Stream<Nip01Event> get stream => controller.stream;

  NdkRequest requestConfig;

  //! our requests tracking obj
  Map<String, dynamic> requests = {};

  RequestState(this.requestConfig);
}
