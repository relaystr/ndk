import 'dart:convert';
import 'dart:typed_data';

import '../../../domain_layer/entities/nip_01_event.dart';
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

    // Try primary upload
    final primaryResult = await _uploadToServer(
      serverUrl: serverUrls.first,
      data: data,
      contentType: contentType,
      authorization: authorization,
    );
    results.add(primaryResult);

    if (primaryResult.success) {
      // Mirror to other servers
      final mirrorResults =
          await Future.wait(serverUrls.skip(1).map((url) => _uploadToServer(
                serverUrl: url,
                data: data,
                contentType: contentType,
                authorization: authorization,
              )));
      results.addAll(mirrorResults);
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

  @override
  Future<Uint8List> getBlob({
    required String sha256,
    required List<String> serverUrls,
    Nip01Event? authorization,
  }) async {
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
}
