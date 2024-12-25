import 'dart:convert';
import 'package:http/http.dart' as http;

/// Data source for making http requests
class HttpRequestDS {
  final http.Client _client;

  /// create new instance of HttpRequestDS
  HttpRequestDS(this._client);

  /// make a get request to the given url
  Future<Map<String, dynamic>> jsonRequest(String url) async {
    http.Response response = await _client
        .get(Uri.parse(url).replace(scheme: 'https'), headers: {"Accept": "application/json"});

    print(response);
    if (response.statusCode != 200) {
      return throw Exception(
          "error fetching STATUS: ${response.statusCode}, Link: $url");
    }
    return jsonDecode(response.body);
  }
}
