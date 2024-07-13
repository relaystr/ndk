import 'package:http/http.dart' as http;

import '../data_layer/data_sources/http_request.dart';

class Initialization {
  /// data sources

  final HttpRequestDS _httpRequestDS = HttpRequestDS(http.Client());

  /// repositories
}
