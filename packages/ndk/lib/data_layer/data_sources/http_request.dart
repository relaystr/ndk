import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:rxdart/rxdart.dart';

/// Upload progress information
class UploadProgress {
  final int sentBytes;
  final int totalBytes;
  final bool isComplete;
  final http.Response? response;
  final Object? error;

  UploadProgress({
    required this.sentBytes,
    required this.totalBytes,
    this.isComplete = false,
    this.response,
    this.error,
  });

  double get progress => totalBytes > 0 ? sentBytes / totalBytes : 0;
  double get percentage => progress * 100;
}

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
    required Object body,
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

  /// Upload data using streaming to avoid loading entire file into memory
  /// Returns a stream of [UploadProgress] that emits progress updates and completes when upload is done
  /// Uses BehaviorSubject so new listeners get the latest progress immediately
  Stream<UploadProgress> putStream({
    required Uri url,
    required Stream<List<int>> body,
    required Map<String, String> headers,
    int? contentLength,
  }) {
    final progressSubject = BehaviorSubject<UploadProgress>.seeded(
      UploadProgress(sentBytes: 0, totalBytes: contentLength ?? 0),
    );

    () async {
      try {
        final request = http.StreamedRequest('PUT', url);

        // Add headers
        request.headers.addAll(headers);

        // Set content length if provided (required by some servers)
        if (contentLength != null) {
          request.contentLength = contentLength;
        }

        // Track progress
        int bytesSent = 0;
        final totalBytes = contentLength ?? 0;

        final progressStream = body.map((chunk) {
          bytesSent += chunk.length;
          progressSubject.add(UploadProgress(
            sentBytes: bytesSent,
            totalBytes: totalBytes,
          ));
          return chunk;
        });

        // Pipe the stream to the request
        progressStream.listen(
          request.sink.add,
          onError: (error) {
            request.sink.addError(error);
            progressSubject.addError(error);
          },
          onDone: request.sink.close,
          cancelOnError: true,
        );

        // Send the request and get response
        final streamedResponse = await _client.send(request);
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode != 200) {
          final error = Exception(
              "error fetching STATUS: ${response.statusCode}, Link: $url");
          progressSubject.addError(error);
          await progressSubject.close();
          return;
        }

        // Upload complete
        progressSubject.add(UploadProgress(
          sentBytes: totalBytes,
          totalBytes: totalBytes,
          isComplete: true,
          response: response,
        ));
        await progressSubject.close();
      } catch (error) {
        progressSubject.addError(error);
        await progressSubject.close();
      }
    }();

    return progressSubject.stream;
  }

  Future<http.Response> post({
    required Uri url,
    required Uint8List body,
    required headers,
  }) async {
    http.Response response = await _client.post(
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

  Future<http.Response> head({
    required Uri url,
    headers,
  }) async {
    http.Response response = await _client.head(
      url,
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception(
          "error fetching STATUS: ${response.statusCode}, Link: $url");
    }

    return response;
  }

  Future<http.Response> get({
    required Uri url,
    headers,
  }) async {
    http.Response response = await _client.get(
      url,
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception(
          "error fetching STATUS: ${response.statusCode}, Link: $url");
    }

    return response;
  }

  Future<http.Response> delete({
    required Uri url,
    required headers,
  }) async {
    http.Response response = await _client.delete(
      url,
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception(
          "error fetching STATUS: ${response.statusCode}, Link: $url");
    }

    return response;
  }
}
