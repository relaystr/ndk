import 'dart:convert';
import 'dart:typed_data';

import '../../../domain_layer/repositories/blossom.dart';
import '../../data_sources/http_request.dart';

class BlossomRepositoryImpl implements BlossomRepository {
  final HttpRequestDS client;
  final List<String> serverUrls;

  BlossomRepositoryImpl({
    required this.client,
    required this.serverUrls,
  }) {
    if (serverUrls.isEmpty) {
      throw ArgumentError('At least one server URL must be provided');
    }
  }

  @override
  Future<List<BlobUploadResult>> uploadBlob(
    Uint8List data, {
    String? contentType,
    UploadStrategy strategy = UploadStrategy.mirrorAfterSuccess,
  }) async {
    switch (strategy) {
      case UploadStrategy.mirrorAfterSuccess:
        return _uploadWithMirroring(data, contentType);
      case UploadStrategy.allSimultaneous:
        return _uploadToAllServers(data, contentType);
      case UploadStrategy.firstSuccess:
        return _uploadToFirstSuccess(data, contentType);
    }
  }

  Future<List<BlobUploadResult>> _uploadWithMirroring(
    Uint8List data,
    String? contentType,
  ) async {
    final results = <BlobUploadResult>[];

    // Try primary upload
    final primaryResult = await _uploadToServer(
      serverUrls.first,
      data,
      contentType,
    );
    results.add(primaryResult);

    if (primaryResult.success) {
      // Mirror to other servers
      final mirrorResults = await Future.wait(serverUrls
          .skip(1)
          .map((url) => _uploadToServer(url, data, contentType)));
      results.addAll(mirrorResults);
    }

    return results;
  }

  Future<List<BlobUploadResult>> _uploadToAllServers(
    Uint8List data,
    String? contentType,
  ) async {
    final results = await Future.wait(
        serverUrls.map((url) => _uploadToServer(url, data, contentType)));
    return results;
  }

  Future<List<BlobUploadResult>> _uploadToFirstSuccess(
    Uint8List data,
    String? contentType,
  ) async {
    for (final url in serverUrls) {
      final result = await _uploadToServer(url, data, contentType);
      if (result.success) {
        return [result];
      }
    }

    // If all servers failed, return all errors
    final results = await _uploadToAllServers(data, contentType);
    return results;
  }

  Future<BlobUploadResult> _uploadToServer(
    String serverUrl,
    Uint8List data,
    String? contentType,
  ) async {
    try {
      final response = await client.put(
        url: Uri.parse('$serverUrl/upload'),
        body: data,
        headers: {
          if (contentType != null) 'Content-Type': contentType,
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

  @override
  Future<Uint8List> getBlob(String sha256) async {
    Exception? lastError;

    for (final url in serverUrls) {
      try {
        final response = await client.get(
          Uri.parse('$url/$sha256'),
        );

        if (response.statusCode == 200) {
          return response.bodyBytes;
        }
        lastError = Exception('HTTP ${response.statusCode}');
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
      }
    }

    throw Exception(
        'Failed to get blob from all servers. Last error: $lastError');
  }

  @override
  Future<List<BlobDescriptor>> listBlobs(
    String pubkey, {
    DateTime? since,
    DateTime? until,
  }) async {
    Exception? lastError;

    for (final url in serverUrls) {
      try {
        final queryParams = <String, String>{
          if (since != null) 'since': '${since.millisecondsSinceEpoch ~/ 1000}',
          if (until != null) 'until': '${until.millisecondsSinceEpoch ~/ 1000}',
        };

        final response = await client.get(
          Uri.parse('$url/list/$pubkey').replace(queryParameters: queryParams),
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
  Future<List<BlobDeleteResult>> deleteBlob(String sha256) async {
    final results = await Future.wait(
        serverUrls.map((url) => _deleteFromServer(url, sha256)));
    return results;
  }

  Future<BlobDeleteResult> _deleteFromServer(
      String serverUrl, String sha256) async {
    try {
      final response = await client.delete(
        Uri.parse('$serverUrl/$sha256'),
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
}
