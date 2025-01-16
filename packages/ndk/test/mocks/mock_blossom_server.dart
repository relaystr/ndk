import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

class MockBlossomServer {
  // In-memory storage for blobs
  final Map<String, _BlobEntry> _blobs = {};
  final int port;
  HttpServer? _server;

  MockBlossomServer({this.port = 3000});

  Router _createRouter() {
    final router = Router();

    // GET /<sha256> - Get Blob
    router.get('/<sha256>', (Request request, String sha256) {
      if (!_blobs.containsKey(sha256)) {
        return Response.notFound('Blob not found');
      }
      return Response.ok(_blobs[sha256]!.data,
          headers: {'Content-Type': _blobs[sha256]!.contentType});
    });

    // HEAD /<sha256> - Has Blob
    router.head('/<sha256>', (Request request, String sha256) {
      if (!_blobs.containsKey(sha256)) {
        return Response.notFound('Blob not found');
      }
      return Response(200, headers: {
        'Content-Length': _blobs[sha256]!.data.length.toString(),
        'Content-Type': _blobs[sha256]!.contentType,
      });
    });

    // PUT /upload - Upload Blob
    router.put('/upload', (Request request) async {
      // Check for authorization header
      final authHeader = request.headers['authorization'];

      if (authHeader == null) {
        return Response.forbidden('Missing authorization');
      }

      try {
        final authEvent =
            json.decode(utf8.decode(base64Decode(authHeader.split(' ')[1])));
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
          .map((entry) => {
                'url': 'http://localhost:$port/${entry.key}',
                'sha256': entry.key,
                'size': entry.value.data.length,
                'type': entry.value.contentType,
                'uploaded':
                    entry.value.uploadedAt.millisecondsSinceEpoch ~/ 1000,
              })
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
        final authEvent =
            json.decode(utf8.decode(base64Decode(authHeader.split(' ')[1])));

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
      return Response(200);
    });

    router.post('/mirror/<sha256>', (Request request, String sha256) async {
      // Check for authorization header
      final authHeader = request.headers['authorization'];

      if (authHeader == null) {
        return Response.forbidden('Missing authorization');
      }

      try {
        final authEvent =
            json.decode(utf8.decode(base64Decode(authHeader.split(' ')[1])));
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
              body: 'Request body must contain a "url" field');
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
          return Response.internalServerError(
              body:
                  'Failed to download from source URL: ${response.statusCode}');
        }

        // Read the response data
        final bytes = await response.expand((chunk) => chunk).toList();
        final data = Uint8List.fromList(bytes);

        // Verify the SHA256 matches
        final computedSha256 = _computeSha256(data);
        if (computedSha256 != sha256) {
          return Response.badRequest(
              body: 'SHA256 mismatch: expected $sha256, got $computedSha256');
        }

        // Store the blob
        _blobs[sha256] = _BlobEntry(
          data: data,
          contentType: response.headers.contentType?.toString() ??
              'application/octet-stream',
          uploader: 'test_pubkey',
          uploadedAt: DateTime.now(),
        );

        // Return the same descriptor format as upload
        return Response.ok(
          json.encode({
            'url': 'http://localhost:$port/$sha256',
            'sha256': sha256,
            'size': data.length,
            'type': _blobs[sha256]!.contentType,
            'uploaded': DateTime.now().millisecondsSinceEpoch ~/ 1000,
          }),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return Response.internalServerError(
            body: 'Failed to mirror blob: ${e.toString()}');
      }
    });

    return router;
  }

  Future<void> start() async {
    final handler = Pipeline()
        .addMiddleware(logRequests())
        .addHandler(_createRouter().call);

    _server = await serve(handler, 'localhost', port);
    print('Mock Blossom Server running on port $port');
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
    final hasTypeTag =
        tags.any((tag) => tag.length >= 2 && tag[0] == 't' && tag[1] == type);

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
