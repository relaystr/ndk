import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Data source for making http requests
class HttpRequestDS {
  final http.Client _client;

  /// create new instance of HttpRequestDS
  HttpRequestDS(this._client);

  /// make a get request to the given url
  Future<Map<String, dynamic>> jsonRequest(String url) async {
    http.Response response = await _client.get(
        Uri.parse(url).replace(scheme: 'https'),
        headers: {"Accept": "application/json"});

    if (response.statusCode != 200) {
      return throw Exception(
          "error fetching STATUS: ${response.statusCode}, Link: $url");
    }
    return jsonDecode(response.body);
  }

  Future<http.Response> put({
    required Uri url,
    required Uint8List body,
    required headers,
  }) async {
    http.Response response = await _client.put(
      url,
      body: body,
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception(
          "error fetching STATUS: ${response.statusCode}, Link: $url");
    }

    return response;
  }

  Future<http.Response> get(Uri url) async {
    http.Response response = await _client.get(url);

    if (response.statusCode != 200) {
      throw Exception(
          "error fetching STATUS: ${response.statusCode}, Link: $url");
    }

    return response;
  }

  Future<http.Response> delete(Uri url) async {
    http.Response response = await _client.delete(url);

    if (response.statusCode != 200) {
      throw Exception(
          "error fetching STATUS: ${response.statusCode}, Link: $url");
    }

    return response;
  }
}
