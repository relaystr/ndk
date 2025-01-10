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
        final authEvent = json.decode(authHeader);
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
        final authEvent = json.decode(authHeader);
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
