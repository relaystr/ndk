import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:ndk/shared/logger/logger.dart';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

/// One request the server received, so a test can assert on what was sent
/// rather than only on what came back.
class MockBlossomRequest {
  final String method;
  final String path;
  final bool hasAuth;

  /// id of the decoded kind 24242 event, null when no readable one was sent
  final String? authEventId;

  /// value of the auth event's `t` tag
  final String? authType;
  final String? authPubkey;

  MockBlossomRequest({
    required this.method,
    required this.path,
    required this.hasAuth,
    this.authEventId,
    this.authType,
    this.authPubkey,
  });

  @override
  String toString() =>
      'MockBlossomRequest($method $path, auth: $hasAuth, type: $authType)';
}

class MockBlossomServer {
  // In-memory storage for blobs
  final Map<String, _BlobEntry> _blobs = {};
  final int port;
  final int uploadStatusCode;
  final int mirrorStatusCode;
  final int deleteStatusCode;

  /// demand an authorization on GET and HEAD too, which a public blossom
  /// server does not. Mutable so a test can seed a blob and only then start
  /// refusing.
  bool requireAuthForReads;

  /// status a refusal answers with. BUD-01 says 401, some servers say 403
  final int authRefusalStatus;

  /// advertise `accept-ranges` so [getBlobStream] takes its chunked path
  /// instead of falling back to a whole-blob download
  final bool supportRangeRequests;

  /// how long each response is held back, to make concurrent requests really
  /// overlap
  final Duration? responseDelay;

  /// every request the server received, oldest first
  final List<MockBlossomRequest> requests = [];

  HttpServer? _server;

  /// report kind
  static const int kReport = 1984;

  MockBlossomServer({
    this.port = 3000,
    this.uploadStatusCode = 200,
    this.mirrorStatusCode = 200,
    this.deleteStatusCode = 200,
    this.requireAuthForReads = false,
    this.authRefusalStatus = 403,
    this.supportRangeRequests = false,
    this.responseDelay,
  });

  /// forget every recorded request
  void clearRequests() => requests.clear();

  /// how many recorded requests match, any null narrowing being ignored
  int countRequests({String? method, String? path, bool? hasAuth}) => requests
      .where((r) => method == null || r.method == method)
      .where((r) => path == null || r.path == path)
      .where((r) => hasAuth == null || r.hasAuth == hasAuth)
      .length;

  /// distinct auth events the client signed, which tells a test whether one
  /// operation signed once or once per server
  Set<String> get signedEventIds =>
      requests.map((r) => r.authEventId).nonNulls.toSet();

  Map<String, dynamic>? _decodeAuthEvent(String? header) {
    if (header == null) return null;
    try {
      return json.decode(utf8.decode(base64Decode(header.split(' ')[1])));
    } catch (_) {
      return null;
    }
  }

  String? _tagValue(Map<String, dynamic>? event, String name) {
    if (event == null) return null;
    final tags = List<List<dynamic>>.from(event['tags']);
    for (final tag in tags) {
      if (tag.length >= 2 && tag[0] == name) return tag[1] as String;
    }
    return null;
  }

  Middleware _recordRequests() => (innerHandler) => (request) async {
        final header = request.headers['authorization'];
        final event = _decodeAuthEvent(header);
        requests.add(
          MockBlossomRequest(
            method: request.method,
            path: '/${request.url.path}',
            hasAuth: header != null,
            authEventId: event?['id'] as String?,
            authType: _tagValue(event, 't'),
            authPubkey: event?['pubkey'] as String?,
          ),
        );
        if (responseDelay != null) {
          await Future.delayed(responseDelay!);
        }
        return innerHandler(request);
      };

  /// null when the read may proceed, a refusal otherwise
  Response? _refuseRead(Request request) {
    if (!requireAuthForReads) return null;
    final authHeader = request.headers['authorization'];
    if (authHeader == null) {
      return Response(authRefusalStatus, body: 'Missing authorization');
    }
    final event = _decodeAuthEvent(authHeader);
    if (event == null || !_verifyAuthEvent(event, 'get')) {
      return Response(authRefusalStatus, body: 'Invalid authorization event');
    }
    return null;
  }

  Router _createRouter() {
    final router = Router();

    // GET /<sha256> - Get Blob
    router.get('/<sha256>', (Request request, String sha256) {
      final refusal = _refuseRead(request);
      if (refusal != null) return refusal;

      if (!_blobs.containsKey(sha256)) {
        return Response.notFound('Blob not found');
      }

      final entry = _blobs[sha256]!;
      final range = supportRangeRequests ? request.headers['range'] : null;
      if (range != null) {
        final match = RegExp(r'bytes=(\d+)-(\d*)').firstMatch(range);
        if (match != null) {
          final start = int.parse(match.group(1)!);
          final end = match.group(2)!.isEmpty
              ? entry.data.length - 1
              : int.parse(match.group(2)!);
          final slice = entry.data.sublist(start, end + 1);
          return Response(
            206,
            body: slice,
            headers: {
              'Content-Type': entry.contentType,
              'Content-Length': slice.length.toString(),
              'Content-Range': 'bytes $start-$end/${entry.data.length}',
              'Accept-Ranges': 'bytes',
            },
          );
        }
      }

      // shelf_router answers HEAD with the GET handler, so this is also what a
      // range probe reads
      return Response.ok(
        entry.data,
        headers: {
          'Content-Type': entry.contentType,
          if (supportRangeRequests) 'Accept-Ranges': 'bytes',
        },
      );
    });

    // GET /static/test.txt - Static test file endpoint
    router.get('/static/test.txt', (Request request) {
      return Response.ok(
        'Static file content for testing',
        headers: {'Content-Type': 'text/plain'},
      );
    });

    // HEAD /<sha256> - Has Blob
    router.head('/<sha256>', (Request request, String sha256) {
      final refusal = _refuseRead(request);
      if (refusal != null) return refusal;

      if (!_blobs.containsKey(sha256)) {
        return Response.notFound('Blob not found');
      }
      return Response(
        200,
        headers: {
          'Content-Length': _blobs[sha256]!.data.length.toString(),
          'Content-Type': _blobs[sha256]!.contentType,
          if (supportRangeRequests) 'Accept-Ranges': 'bytes',
        },
      );
    });

    // PUT /upload - Upload Blob
    router.put('/upload', (Request request) async {
      // Check for authorization header
      final authHeader = request.headers['authorization'];

      if (authHeader == null) {
        return Response.forbidden('Missing authorization');
      }

      try {
        final authEvent = json.decode(
          utf8.decode(base64Decode(authHeader.split(' ')[1])),
        );
        if (!_verifyAuthEvent(authEvent, 'upload')) {
          return Response.forbidden('Invalid authorization event');
        }
      } catch (e) {
        return Response.forbidden('Invalid authorization format');
      }

      // Read the request body
      final bytes = await request.read().expand((chunk) => chunk).toList();
      final data = Uint8List.fromList(bytes);

      final sha256 = _computeSha256(data);
      final contentType =
          request.headers['content-type'] ?? 'application/octet-stream';

      _blobs[sha256] = _BlobEntry(
        data: data,
        contentType: contentType,
        uploader: 'test_pubkey',
        uploadedAt: DateTime.now(),
      );

      return Response(
        uploadStatusCode,
        body: json.encode({
          'url': 'http://localhost:$port/$sha256',
          'sha256': sha256,
          'size': data.length,
          'type': contentType,
          'uploaded': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    });

    // PUT /media - Upload Media Blob
    router.put('/media', (Request request) async {
      // Check for authorization header
      final authHeader = request.headers['authorization'];

      if (authHeader == null) {
        return Response.forbidden('Missing authorization');
      }

      try {
        final authEvent = json.decode(
          utf8.decode(base64Decode(authHeader.split(' ')[1])),
        );
        if (!_verifyAuthEvent(authEvent, 'media')) {
          return Response.forbidden('Invalid authorization event');
        }
      } catch (e) {
        return Response.forbidden('Invalid authorization format');
      }

      // Read the request body
      final bytes = await request.read().expand((chunk) => chunk).toList();
      final data = Uint8List.fromList(bytes);

      final sha256 = _computeSha256(data);
      final contentType =
          request.headers['content-type'] ?? 'application/octet-stream';

      _blobs[sha256] = _BlobEntry(
        data: data,
        contentType: contentType,
        uploader: 'test_pubkey',
        uploadedAt: DateTime.now(),
      );

      return Response.ok(
        json.encode({
          'url': 'http://localhost:$port/$sha256',
          'sha256': sha256,
          'size': data.length,
          'type': contentType,
          'uploaded': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    });

    // GET /list/<pubkey> - List Blobs
    router.get('/list/<pubkey>', (Request request, String pubkey) {
      final authHeader = request.headers['authorization'];

      if (authHeader == null) {
        return Response.forbidden('Missing authorization');
      }

      try {
        final authEvent = json.decode(
          utf8.decode(base64Decode(authHeader.split(' ')[1])),
        );
        if (!_verifyAuthEvent(authEvent, 'list')) {
          return Response.forbidden('Invalid authorization event');
        }
      } catch (e) {
        return Response.forbidden('Invalid authorization format');
      }

      final since = int.tryParse(request.url.queryParameters['since'] ?? '');
      final until = int.tryParse(request.url.queryParameters['until'] ?? '');

      final blobs = _blobs.entries
          .where((entry) => entry.value.uploader == pubkey)
          .where((entry) {
            final timestamp =
                entry.value.uploadedAt.millisecondsSinceEpoch ~/ 1000;
            if (since != null && timestamp < since) return false;
            if (until != null && timestamp > until) return false;
            return true;
          })
          .map(
            (entry) => {
              'url': 'http://localhost:$port/${entry.key}',
              'sha256': entry.key,
              'size': entry.value.data.length,
              'type': entry.value.contentType,
              'uploaded': entry.value.uploadedAt.millisecondsSinceEpoch ~/ 1000,
            },
          )
          .toList();

      return Response.ok(
        json.encode(blobs),
        headers: {'Content-Type': 'application/json'},
      );
    });

    // DELETE /<sha256> - Delete Blob
    router.delete('/<sha256>', (Request request, String sha256) {
      final authHeader = request.headers['authorization'];
      if (authHeader == null) {
        return Response.forbidden('Missing authorization');
      }

      try {
        final authEvent = json.decode(
          utf8.decode(base64Decode(authHeader.split(' ')[1])),
        );

        if (!_verifyAuthEvent(authEvent, 'delete')) {
          return Response.forbidden('Invalid authorization event');
        }
      } catch (e) {
        return Response.forbidden('Invalid authorization format');
      }

      if (!_blobs.containsKey(sha256)) {
        return Response.notFound('Blob not found');
      }

      _blobs.remove(sha256);
      return Response(deleteStatusCode);
    });

    router.put('/mirror', (Request request) async {
      // Check for authorization header
      final authHeader = request.headers['authorization'];

      if (authHeader == null) {
        return Response.forbidden('Missing authorization');
      }

      try {
        final authEvent = json.decode(
          utf8.decode(base64Decode(authHeader.split(' ')[1])),
        );
        if (!_verifyAuthEvent(authEvent, 'upload')) {
          return Response.forbidden('Invalid authorization event');
        }
      } catch (e) {
        return Response.forbidden('Invalid authorization format');
      }

      // Parse the request body to get the URL
      final String body = await request.readAsString();
      Map<String, dynamic> requestData;
      try {
        requestData = json.decode(body);
        if (!requestData.containsKey('url')) {
          return Response.badRequest(
            body: 'Request body must contain a "url" field',
          );
        }
      } catch (e) {
        return Response.badRequest(body: 'Invalid JSON body');
      }

      // Download the blob from the provided URL
      try {
        final sourceUrl = requestData['url'];
        final httpClient = HttpClient();
        final request = await httpClient.getUrl(Uri.parse(sourceUrl));
        final response = await request.close();

        if (response.statusCode != 200) {
          await response.drain();
          httpClient.close();
          return Response.internalServerError(
            body: 'Failed to download from source URL: ${response.statusCode}',
          );
        }

        // Read the response data

        final bytes = await response.expand((chunk) => chunk).toList();
        final data = Uint8List.fromList(bytes);

        // compute sha256
        final computedSha256 = _computeSha256(data);

        // Store the blob
        _blobs[computedSha256] = _BlobEntry(
          data: data,
          contentType: response.headers.contentType?.toString() ??
              'application/octet-stream',
          uploader: 'test_pubkey',
          uploadedAt: DateTime.now(),
        );

        httpClient.close();
        // Return the same descriptor format as upload
        return Response(
          mirrorStatusCode,
          body: json.encode({
            'url': 'http://localhost:$port/$computedSha256',
            'sha256': computedSha256,
            'size': data.length,
            'type': _blobs[computedSha256]!.contentType,
            'uploaded': DateTime.now().millisecondsSinceEpoch ~/ 1000,
          }),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return Response.internalServerError(
          body: 'Failed to mirror blob: ${e.toString()}',
        );
      }
    });

    router.put('/report', (Request request) async {
      final String body = await request.readAsString();
      Map<String, dynamic> requestData;
      try {
        requestData = json.decode(body);
      } catch (e) {
        return Response.badRequest(body: 'Invalid JSON body');
      }
      if (requestData['kind'] != kReport) {
        return Response.badRequest(body: 'Invalid kind');
      }
      return Response.ok(
        '{"status": "ok"}',
        headers: {'Content-Type': 'application/json'},
      );
    });

    return router;
  }

  Future<void> start() async {
    final handler = Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware(_recordRequests())
        .addHandler(_createRouter().call);

    _server = await serve(handler, 'localhost', port);
    Logger.log.i(() => 'Mock Blossom Server running on port $port');
  }

  Future<void> stop() async {
    await _server?.close();
    _server = null;
  }

  // Helper methods
  String _computeSha256(List<int> data) {
    return sha256.convert(data).toString();
  }

  bool _verifyAuthEvent(Map<String, dynamic> event, String type) {
    // Simple verification for testing purposes
    if (event['kind'] != 24242) return false;

    final tags = List<List<dynamic>>.from(event['tags']);
    final hasTypeTag = tags.any(
      (tag) => tag.length >= 2 && tag[0] == 't' && tag[1] == type,
    );

    return hasTypeTag;
  }
}

class _BlobEntry {
  final Uint8List data;
  final String contentType;
  final String uploader;
  final DateTime uploadedAt;

  _BlobEntry({
    required this.data,
    required this.contentType,
    required this.uploader,
    required this.uploadedAt,
  });
}

// Example usage in tests
void main() async {
  final server = MockBlossomServer(port: 3000);
  await server.start();

  // Run your tests here

  await server.stop();
}
