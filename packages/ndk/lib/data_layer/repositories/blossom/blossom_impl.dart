import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../../../domain_layer/entities/blossom_blobs.dart';
import '../../../domain_layer/entities/nip_01_event.dart';
import '../../../domain_layer/entities/tuple.dart';
import '../../../domain_layer/repositories/blossom.dart';
import '../../data_sources/http_request.dart';

class BlossomRepositoryImpl implements BlossomRepository {
  final HttpRequestDS client;

  BlossomRepositoryImpl({
    required this.client,
  });

  @override
  Future<List<BlobUploadResult>> uploadBlob({
    required Uint8List data,
    required Nip01Event authorization,
    String? contentType,
    required List<String> serverUrls,
    UploadStrategy strategy = UploadStrategy.mirrorAfterSuccess,
  }) async {
    switch (strategy) {
      case UploadStrategy.mirrorAfterSuccess:
        return _uploadWithMirroring(
          data: data,
          serverUrls: serverUrls,
          contentType: contentType,
          authorization: authorization,
        );
      case UploadStrategy.allSimultaneous:
        return _uploadToAllServers(
          data: data,
          serverUrls: serverUrls,
          contentType: contentType,
          authorization: authorization,
        );
      case UploadStrategy.firstSuccess:
        return _uploadToFirstSuccess(
          data: data,
          serverUrls: serverUrls,
          contentType: contentType,
          authorization: authorization,
        );
    }
  }

  Future<List<BlobUploadResult>> _uploadWithMirroring({
    required Uint8List data,
    required Nip01Event authorization,
    required List<String> serverUrls,
    String? contentType,
  }) async {
    final results = <BlobUploadResult>[];
    BlobUploadResult? successfulUpload;

    // Try servers until we get a successful upload
    for (final serverUrl in serverUrls) {
      final result = await _uploadToServer(
        serverUrl: serverUrl,
        data: data,
        contentType: contentType,
        authorization: authorization,
      );
      results.add(result);

      if (result.success) {
        successfulUpload = result;
        break;
      }
    }

    // If we found a working server, mirror to all other servers that haven't been tried yet
    if (successfulUpload != null) {
      // Get the index where we succeeded
      final successIndex = serverUrls.indexOf(successfulUpload.serverUrl);

      // Mirror to remaining servers (ones we haven't tried yet)
      final remainingServers = serverUrls.sublist(successIndex + 1);
      if (remainingServers.isNotEmpty) {
        final mirrorResults = await Future.wait(
          remainingServers.map((url) => _mirrorToServer(
                fileUrl: successfulUpload!.descriptor!.url,
                serverUrl: url,
                sha256: successfulUpload.descriptor!.sha256,
                authorization: authorization,
              )),
        );
        results.addAll(mirrorResults);
      }
    }

    return results;
  }

  Future<List<BlobUploadResult>> _uploadToAllServers({
    required Uint8List data,
    required List<String> serverUrls,
    required Nip01Event authorization,
    String? contentType,
  }) async {
    final results = await Future.wait(serverUrls.map((url) => _uploadToServer(
          serverUrl: url,
          data: data,
          contentType: contentType,
          authorization: authorization,
        )));
    return results;
  }

  Future<List<BlobUploadResult>> _uploadToFirstSuccess({
    required Uint8List data,
    required List<String> serverUrls,
    required Nip01Event authorization,
    String? contentType,
  }) async {
    for (final url in serverUrls) {
      final result = await _uploadToServer(
        serverUrl: url,
        data: data,
        contentType: contentType,
        authorization: authorization,
      );
      if (result.success) {
        return [result];
      }
    }

    // If all servers failed, return all errors
    final results = await _uploadToAllServers(
      data: data,
      serverUrls: serverUrls,
      contentType: contentType,
      authorization: authorization,
    );
    return results;
  }

  /// Upload a file to a server
  Future<BlobUploadResult> _uploadToServer({
    required String serverUrl,
    required Uint8List data,
    Nip01Event? authorization,
    String? contentType,
  }) async {
    try {
      final response = await client.put(
        url: Uri.parse('$serverUrl/upload'),
        body: data,
        headers: {
          if (contentType != null) 'Content-Type': contentType,
          if (authorization != null)
            'Authorization': "Nostr ${authorization.toBase64()}",
          'Content-Length': '${data.length}',
        },
      );

      if (response.statusCode != 200) {
        return BlobUploadResult(
          serverUrl: serverUrl,
          success: false,
          error: 'HTTP ${response.statusCode}',
        );
      }

      return BlobUploadResult(
        serverUrl: serverUrl,
        success: true,
        descriptor: BlobDescriptor.fromJson(jsonDecode(response.body)),
      );
    } catch (e) {
      return BlobUploadResult(
        serverUrl: serverUrl,
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Mirror a file from one server to another, based on the file URL
  Future<BlobUploadResult> _mirrorToServer({
    required String fileUrl,
    required String serverUrl,
    required String sha256,
    required Nip01Event authorization,
  }) async {
    final jsonMsg = {"url": fileUrl};

    final Uint8List myBody =
        Uint8List.fromList(utf8.encode(jsonEncode(jsonMsg)));
    try {
      // Mirror endpoint is POST /mirror/<sha256>
      final response = await client.post(
        url: Uri.parse('$serverUrl/mirror/$sha256'),
        body: myBody,
        headers: {
          'Authorization': "Nostr ${authorization.toBase64()}",
        },
      );

      if (response.statusCode != 200) {
        return BlobUploadResult(
          serverUrl: serverUrl,
          success: false,
          error: 'HTTP ${response.statusCode}',
        );
      }

      return BlobUploadResult(
        serverUrl: serverUrl,
        success: true,
        descriptor: BlobDescriptor.fromJson(jsonDecode(response.body)),
      );
    } catch (e) {
      return BlobUploadResult(
        serverUrl: serverUrl,
        success: false,
        error: e.toString(),
      );
    }
  }

  @override
  Future<BlobResponse> getBlob({
    required String sha256,
    required List<String> serverUrls,
    Nip01Event? authorization,
    int? start,
    int? end,
  }) async {
    Exception? lastError;

    for (final url in serverUrls) {
      try {
        final headers = <String, String>{};
        if (start != null) {
          // Create range header in format "bytes=start-end"
          // If end is null, it means "until the end of the file"
          headers['range'] = 'bytes=$start-${end ?? ''}';
        }

        final response = await client.get(
          url: Uri.parse('$url/$sha256'),
          headers: headers,
        );

        // Check for both 200 (full content) and 206 (partial content) status codes
        if (response.statusCode == 200 || response.statusCode == 206) {
          return BlobResponse(
            data: response.bodyBytes,
            mimeType: response.headers['content-type'],
            contentLength:
                int.tryParse(response.headers['content-length'] ?? ''),
            contentRange: response.headers['content-range'] ?? '',
          );
        }
        lastError = Exception('HTTP ${response.statusCode}');
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
      }
    }

    throw Exception(
        'Failed to get blob from any of the servers. Last error: $lastError');
  }

  /// first value is whether the server supports range requests \
  /// second value is the content length of the blob in bytes
  @override
  Future<Tuple<bool, int?>> supportsRangeRequests({
    required String sha256,
    required String serverUrl,
  }) async {
    try {
      final response = await client.head(
        url: Uri.parse('$serverUrl/$sha256'),
      );

      final acceptRanges = response.headers['accept-ranges'];
      final contentLength =
          int.tryParse(response.headers['content-length'] ?? '');
      return Tuple(acceptRanges?.toLowerCase() == 'bytes', contentLength);
    } catch (e) {
      return Tuple(false, null);
    }
  }

  @override
  Future<Stream<BlobResponse>> getBlobStream({
    required String sha256,
    required List<String> serverUrls,
    Nip01Event? authorization,
    int chunkSize = 1024 * 1024, // 1MB chunks
  }) async {
    // Find a server that supports range requests
    String? supportedServer;
    int? contentLength;

    for (final url in serverUrls) {
      try {
        final rangeResponse = await supportsRangeRequests(
          sha256: sha256,
          serverUrl: url,
        );
        if (rangeResponse.first) {
          supportedServer = url;
          contentLength = rangeResponse.second;
          break;
        }
      } catch (_) {
        continue;
      }
    }

    if (supportedServer == null || contentLength == null) {
      // Fallback to regular download if no server supports range requests
      final bytes = await getBlob(sha256: sha256, serverUrls: serverUrls);
      return Stream.value(bytes);
    }

    // Create a stream controller to manage the chunks
    final controller = StreamController<BlobResponse>();

    // Start downloading chunks
    int offset = 0;
    while (offset < contentLength) {
      final end = (offset + chunkSize - 1).clamp(0, contentLength - 1);

      try {
        final chunk = await getBlob(
          sha256: sha256,
          serverUrls: [supportedServer],
          start: offset,
          end: end,
        );
        controller.add(chunk);
        offset = end + 1;
      } catch (e) {
        await controller.close();
        rethrow;
      }
    }

    await controller.close();
    return controller.stream;
  }

  @override
  Future<List<BlobDescriptor>> listBlobs({
    required pubkey,
    required List<String> serverUrls,
    DateTime? since,
    DateTime? until,
    Nip01Event? authorization,
  }) async {
    Exception? lastError;

    for (final url in serverUrls) {
      try {
        final queryParams = <String, String>{
          if (since != null) 'since': '${since.millisecondsSinceEpoch ~/ 1000}',
          if (until != null) 'until': '${until.millisecondsSinceEpoch ~/ 1000}',
        };

        final response = await client.get(
          url: Uri.parse('$url/list/$pubkey')
              .replace(queryParameters: queryParams),
        );

        if (response.statusCode == 200) {
          final List<dynamic> json = jsonDecode(response.body);
          return json.map((j) => BlobDescriptor.fromJson(j)).toList();
        }
        lastError = Exception('HTTP ${response.statusCode}');
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
      }
    }

    throw Exception(
        'Failed to list blobs from all servers. Last error: $lastError');
  }

  @override
  Future<List<BlobDeleteResult>> deleteBlob({
    required String sha256,
    required List<String> serverUrls,
    required Nip01Event authorization,
  }) async {
    final results = await Future.wait(serverUrls.map((url) => _deleteFromServer(
          serverUrl: url,
          sha256: sha256,
          authorization: authorization,
        )));
    return results;
  }

  Future<BlobDeleteResult> _deleteFromServer({
    required String serverUrl,
    required String sha256,
    required Nip01Event authorization,
  }) async {
    try {
      final response = await client.delete(
        url: Uri.parse('$serverUrl/$sha256'),
        headers: {
          'Authorization': "Nostr ${authorization.toBase64()}",
        },
      );

      return BlobDeleteResult(
        serverUrl: serverUrl,
        success: response.statusCode == 200,
        error:
            response.statusCode != 200 ? 'HTTP ${response.statusCode}' : null,
      );
    } catch (e) {
      return BlobDeleteResult(
        serverUrl: serverUrl,
        success: false,
        error: e.toString(),
      );
    }
  }

  @override
  Future<BlobResponse> directDownload({
    required Uri url,
  }) async {
    final response = await client.get(url: url);
    return BlobResponse(
      data: response.bodyBytes,
      mimeType: response.headers['content-type'],
      contentLength: int.tryParse(response.headers['content-length'] ?? ''),
      contentRange: response.headers['content-range'] ?? '',
    );
  }
}
