import 'package:dart_ndk/dart_ndk.dart';
import 'package:http/http.dart' as http;

import '../data_layer/data_sources/http_request.dart';
import 'global_state.dart';

class Initialization {
  /// data sources

  final HttpRequestDS _httpRequestDS = HttpRequestDS(http.Client());

  /// repositories

  /// state obj

  final relayManger = RelayManager();
  final relayJitManager = RelayJitManager();
}
