import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:rxdart/rxdart.dart';

import '../../../domain_layer/entities/blob_upload_progress.dart';
import '../../../domain_layer/entities/blossom_authorization.dart';
import '../../../domain_layer/entities/blossom_blobs.dart';
import '../../../domain_layer/entities/blossom_strategies.dart';
import '../../../domain_layer/entities/file_hash_progress.dart';
import '../../../domain_layer/entities/nip_01_event.dart';
import '../../../domain_layer/entities/tuple.dart';
import '../../../domain_layer/repositories/blossom.dart';
import '../../data_sources/http_request.dart';
import '../../io/file_io.dart';
import '../../models/nip_01_event_model.dart';

bool _isSuccessStatus(int statusCode) => statusCode >= 200 && statusCode < 300;

String _authHeader(Nip01Event event) =>
    "Nostr ${Nip01EventModel.fromEntity(event).toBase64()}";

/// Whether a server refused for want of an identity, which is an invitation to
/// try again with one. BUD-01 says 401 and some servers say 403, but a 403 on
/// a request that already carried an authorization refuses that identity
/// rather than asking for one, so replaying it would change nothing.
bool _isAuthRefusal(Object error, {required bool sentAuth}) =>
    error is HttpRequestException &&
    (error.statusCode == 401 || (!sentAuth && error.statusCode == 403));

/// What to send before anything has been refused: the upfront event, or the
/// one an earlier refusal in this same operation already signed.
Nip01Event? _initial(BlossomAuthorization authorization) =>
    authorization.upfront ?? authorization.resolved;

/// Sends, and sends once more with a freshly signed event if the server
/// answered by asking for one.
Future<T> _withAuthRetry<T>(
  BlossomAuthorization authorization,
  Future<T> Function(Nip01Event? authEvent) send,
) async {
  final initial = _initial(authorization);
  try {
    return await send(initial);
  } catch (e) {
    if (!_isAuthRefusal(e, sentAuth: initial != null)) rethrow;
    final signed = await authorization.onRefusal();
    if (signed == null) rethrow;
    return await send(signed);
  }
}

class BlossomRepositoryImpl implements BlossomRepository {
  final HttpRequestDS client;
  final FileIO fileIO;

  BlossomRepositoryImpl({required this.client, required this.fileIO});

  @override
  Stream<BlobUploadProgress> uploadBlob({
    required Stream<List<int>> Function() dataStreamFactory,
    required int contentLength,
    required BlossomAuthorization authorization,
    String? contentType,
    required List<String> serverUrls,
    UploadStrategy strategy = UploadStrategy.mirrorAfterSuccess,
    bool mediaOptimisation = false,
  }) async* {
    switch (strategy) {
      case UploadStrategy.mirrorAfterSuccess:
        yield* _uploadWithMirroring(
          dataStreamFactory: dataStreamFactory,
          contentLength: contentLength,
          serverUrls: serverUrls,
          contentType: contentType,
          authorization: authorization,
          mediaOptimisation: mediaOptimisation,
        );
      case UploadStrategy.allSimultaneous:
        yield* _uploadToAllServers(
          dataStreamFactory: dataStreamFactory,
          contentLength: contentLength,
          serverUrls: serverUrls,
          contentType: contentType,
          authorization: authorization,
          mediaOptimisation: mediaOptimisation,
        );
      case UploadStrategy.firstSuccess:
        yield* _uploadToFirstSuccess(
          dataStreamFactory: dataStreamFactory,
          contentLength: contentLength,
          serverUrls: serverUrls,
          contentType: contentType,
          authorization: authorization,
          mediaOptimisation: mediaOptimisation,
        );
    }
  }

  @override
  Stream<BlobUploadProgress> uploadBlobFromFile({
    required String filePath,
    required BlossomAuthorization authorization,
    String? contentType,
    required List<String> serverUrls,
    UploadStrategy strategy = UploadStrategy.mirrorAfterSuccess,
    bool mediaOptimisation = false,
  }) async* {
    // Get file size without reading the file content
    final totalSize = await fileIO.getFileSize(filePath);

    // Create factory that reads file each time from disk
    Stream<List<int>> streamFactory() =>
        fileIO.readFileAsStream(filePath, chunkSize: 1024 * 1024);

    switch (strategy) {
      case UploadStrategy.mirrorAfterSuccess:
        yield* _uploadWithMirroring(
          dataStreamFactory: streamFactory,
          contentLength: totalSize,
          serverUrls: serverUrls,
          contentType: contentType,
          authorization: authorization,
          mediaOptimisation: mediaOptimisation,
        );
      case UploadStrategy.allSimultaneous:
        yield* _uploadToAllServers(
          dataStreamFactory: streamFactory,
          contentLength: totalSize,
          serverUrls: serverUrls,
          contentType: contentType,
          authorization: authorization,
          mediaOptimisation: mediaOptimisation,
        );
      case UploadStrategy.firstSuccess:
        yield* _uploadToFirstSuccess(
          dataStreamFactory: streamFactory,
          contentLength: totalSize,
          serverUrls: serverUrls,
          contentType: contentType,
          authorization: authorization,
          mediaOptimisation: mediaOptimisation,
        );
    }
  }

  Stream<BlobUploadProgress> _uploadWithMirroring({
    required Stream<List<int>> Function() dataStreamFactory,
    required int contentLength,
    required BlossomAuthorization authorization,
    required List<String> serverUrls,
    String? contentType,
    bool mediaOptimisation = false,
  }) async* {
    final results = <BlobUploadResult>[];
    BlobUploadResult? successfulUpload;

    // Try servers until we get a successful upload
    for (final serverUrl in serverUrls) {
      try {
        await for (final progress in _uploadToServer(
          serverUrl: serverUrl,
          dataStreamFactory: dataStreamFactory,
          contentLength: contentLength,
          contentType: contentType,
          authorization: authorization,
          mediaOptimisation: mediaOptimisation,
        )) {
          yield BlobUploadProgress(
            currentServer: serverUrl,
            sentBytes: progress.sentBytes,
            totalBytes: progress.totalBytes,
            completedUploads: results,
            phase: UploadPhase.uploading,
            progressPhase: progress.progress,
          );

          if (progress.isComplete && progress.response != null) {
            final result = BlobUploadResult(
              serverUrl: serverUrl,
              success: true,
              descriptor: BlobDescriptor.fromJson(
                jsonDecode(progress.response!.body),
              ),
            );
            results.add(result);
            successfulUpload = result;
            break;
          } else if (progress.isComplete && progress.error != null) {
            final result = BlobUploadResult(
              serverUrl: serverUrl,
              success: false,
              error: progress.error.toString(),
            );
            results.add(result);
          }
        }
      } catch (e) {
        // Handle network exceptions (e.g., host lookup failures)
        final result = BlobUploadResult(
          serverUrl: serverUrl,
          success: false,
          error: e.toString(),
        );
        results.add(result);
      }

      if (successfulUpload != null) break;
    }

    // If we found a working server, mirror to all other servers that haven't been tried yet
    if (successfulUpload != null) {
      final successIndex = serverUrls.indexOf(successfulUpload.serverUrl);
      final remainingServers = serverUrls.sublist(successIndex + 1);

      if (remainingServers.isNotEmpty) {
        var mirrorsCompleted = 0;
        final mirrorsTotal = remainingServers.length;

        yield BlobUploadProgress(
          currentServer: successfulUpload.serverUrl,
          sentBytes: contentLength,
          totalBytes: contentLength,
          completedUploads: List.from(results),
          phase: UploadPhase.mirroring,
          progressPhase: 0,
          mirrorsTotal: mirrorsTotal,
          mirrorsCompleted: mirrorsCompleted,
        );

        for (final url in remainingServers) {
          final mirrorResult = await mirrorToServer(
            fileUrl: successfulUpload.descriptor!.url,
            serverUrl: url,
            sha256: successfulUpload.descriptor!.sha256,
            authorization: authorization,
          );
          results.add(mirrorResult);
          mirrorsCompleted++;

          yield BlobUploadProgress(
            currentServer: url,
            sentBytes: contentLength,
            totalBytes: contentLength,
            completedUploads: List.from(results),
            phase: UploadPhase.mirroring,
            progressPhase:
                mirrorsTotal > 0 ? mirrorsCompleted / mirrorsTotal : 1,
            mirrorsTotal: mirrorsTotal,
            mirrorsCompleted: mirrorsCompleted,
          );
        }
      }
    }

    // Emit final progress
    yield BlobUploadProgress(
      currentServer: '',
      sentBytes: successfulUpload != null ? contentLength : 0,
      totalBytes: contentLength,
      completedUploads: results,
      phase: UploadPhase.mirroring,
      progressPhase: 1,
      isComplete: true,
    );
  }

  Stream<BlobUploadProgress> _uploadToAllServers({
    required Stream<List<int>> Function() dataStreamFactory,
    required int contentLength,
    required List<String> serverUrls,
    required BlossomAuthorization authorization,
    String? contentType,
    bool mediaOptimisation = false,
  }) async* {
    final results = <BlobUploadResult>[];
    final progressSubject = BehaviorSubject<BlobUploadProgress>.seeded(
      BlobUploadProgress(
        currentServer: '',
        sentBytes: 0,
        totalBytes: contentLength,
        completedUploads: [],
        phase: UploadPhase.uploading,
        progressPhase: 0,
      ),
    );

    // Start all uploads simultaneously
    final uploadFutures = serverUrls.map((serverUrl) async {
      try {
        await for (final progress in _uploadToServer(
          serverUrl: serverUrl,
          dataStreamFactory: dataStreamFactory,
          contentLength: contentLength,
          contentType: contentType,
          authorization: authorization,
          mediaOptimisation: mediaOptimisation,
        )) {
          // Emit intermediate per-server progress updates
          if (!progress.isComplete) {
            progressSubject.add(
              BlobUploadProgress(
                currentServer: serverUrl,
                sentBytes: progress.sentBytes,
                totalBytes: progress.totalBytes,
                completedUploads: List.from(results),
                phase: UploadPhase.uploading,
                progressPhase: progress.progress,
              ),
            );
            continue;
          }
          if (progress.isComplete && progress.response != null) {
            final result = BlobUploadResult(
              serverUrl: serverUrl,
              success: true,
              descriptor: BlobDescriptor.fromJson(
                jsonDecode(progress.response!.body),
              ),
            );
            results.add(result);
            progressSubject.add(
              BlobUploadProgress(
                currentServer: serverUrl,
                sentBytes: progress.sentBytes,
                totalBytes: contentLength,
                completedUploads: List.from(results),
                phase: UploadPhase.uploading,
                progressPhase: progress.progress,
              ),
            );
          } else if (progress.isComplete && progress.error != null) {
            final result = BlobUploadResult(
              serverUrl: serverUrl,
              success: false,
              error: progress.error.toString(),
            );
            results.add(result);
            progressSubject.add(
              BlobUploadProgress(
                currentServer: serverUrl,
                sentBytes: progress.sentBytes,
                totalBytes: contentLength,
                completedUploads: List.from(results),
                phase: UploadPhase.uploading,
                progressPhase: progress.progress,
              ),
            );
          }
        }
      } catch (e) {
        // Handle network exceptions (e.g., host lookup failures)
        final result = BlobUploadResult(
          serverUrl: serverUrl,
          success: false,
          error: e.toString(),
        );
        results.add(result);
        progressSubject.add(
          BlobUploadProgress(
            currentServer: serverUrl,
            sentBytes: 0,
            totalBytes: contentLength,
            completedUploads: List.from(results),
            phase: UploadPhase.uploading,
            progressPhase: 0,
          ),
        );
      }
    }).toList();

    // When all uploads complete, close the stream
    Future.wait(uploadFutures).then((_) async {
      progressSubject.add(
        BlobUploadProgress(
          currentServer: '',
          sentBytes: contentLength,
          totalBytes: contentLength,
          completedUploads: List.from(results),
          phase: UploadPhase.mirroring,
          progressPhase: 1,
          isComplete: true,
        ),
      );
      await progressSubject.close();
    });

    // Forward progress updates until the subject closes
    yield* progressSubject.stream;
  }

  Stream<BlobUploadProgress> _uploadToFirstSuccess({
    required Stream<List<int>> Function() dataStreamFactory,
    required int contentLength,
    required List<String> serverUrls,
    required BlossomAuthorization authorization,
    String? contentType,
    bool mediaOptimisation = false,
  }) async* {
    final results = <BlobUploadResult>[];

    for (final url in serverUrls) {
      try {
        await for (final progress in _uploadToServer(
          serverUrl: url,
          dataStreamFactory: dataStreamFactory,
          contentLength: contentLength,
          contentType: contentType,
          authorization: authorization,
          mediaOptimisation: mediaOptimisation,
        )) {
          yield BlobUploadProgress(
            currentServer: url,
            sentBytes: progress.sentBytes,
            totalBytes: progress.totalBytes,
            completedUploads: results,
            phase: UploadPhase.uploading,
            progressPhase: progress.progress,
          );

          if (progress.isComplete && progress.response != null) {
            final result = BlobUploadResult(
              serverUrl: url,
              success: true,
              descriptor: BlobDescriptor.fromJson(
                jsonDecode(progress.response!.body),
              ),
            );
            results.add(result);

            yield BlobUploadProgress(
              currentServer: url,
              sentBytes: progress.sentBytes,
              totalBytes: contentLength,
              completedUploads: results,
              phase: UploadPhase.mirroring,
              progressPhase: 1,
              isComplete: true,
            );
            return;
          } else if (progress.isComplete && progress.error != null) {
            results.add(
              BlobUploadResult(
                serverUrl: url,
                success: false,
                error: progress.error.toString(),
              ),
            );
          }
        }
      } catch (e) {
        // Handle network exceptions (e.g., host lookup failures)
        results.add(
          BlobUploadResult(serverUrl: url, success: false, error: e.toString()),
        );
      }
    }

    // All servers failed
    yield BlobUploadProgress(
      currentServer: '',
      sentBytes: 0,
      totalBytes: contentLength,
      completedUploads: results,
      phase: UploadPhase.mirroring,
      progressPhase: 1,
      isComplete: true,
    );
  }

  /// Upload a file to a server \
  /// If [mediaOptimisation] is true, the server will optimise the file for media streaming using the /media endpoint [BUD-05]
  Stream<UploadProgress> _uploadToServer({
    required String serverUrl,
    required Stream<List<int>> Function() dataStreamFactory,
    required int contentLength,
    BlossomAuthorization authorization = const BlossomAuthorization.none(),
    String? contentType,
    bool mediaOptimisation = false,
  }) async* {
    final endpointUrl =
        mediaOptimisation ? '$serverUrl/media' : '$serverUrl/upload';

    Map<String, String> headersFor(Nip01Event? authEvent) => {
          if (contentType != null) 'Content-Type': contentType,
          if (authEvent != null) 'Authorization': _authHeader(authEvent),
          'Content-Length': '$contentLength',
        };

    Stream<UploadProgress> send(Nip01Event? authEvent) => client.putStream(
          url: Uri.parse(endpointUrl),
          body: dataStreamFactory(),
          headers: headersFor(authEvent),
          contentLength: contentLength,
        );

    final initial = _initial(authorization);
    try {
      // consumed rather than delegated with yield*, which would forward the
      // refusal straight to the caller instead of raising it here
      await for (final progress in send(initial)) {
        yield progress;
      }
      return;
    } catch (e) {
      if (!_isAuthRefusal(e, sentAuth: initial != null)) rethrow;
      final signed = await authorization.onRefusal();
      if (signed == null) rethrow;
      // the body is read from scratch, so progress starts over
      yield* send(signed);
    }
  }

  /// Mirror a file from one server to another, based on the file URL
  @override
  Future<BlobUploadResult> mirrorToServer({
    required String fileUrl,
    required String serverUrl,
    required String sha256,
    required BlossomAuthorization authorization,
  }) async {
    final jsonMsg = {"url": fileUrl};

    final String myBody = jsonEncode(jsonMsg);
    try {
      // Mirror endpoint is PUT /mirror/
      final response = await _withAuthRetry(
        authorization,
        (authEvent) => client.put(
          url: Uri.parse('$serverUrl/mirror'),
          body: myBody,
          headers: {
            if (authEvent != null) 'Authorization': _authHeader(authEvent),
            'Content-Type': 'application/json',
          },
        ),
      );

      if (!_isSuccessStatus(response.statusCode)) {
        return BlobUploadResult(
          serverUrl: serverUrl,
          success: false,
          error: 'HTTP ${response.statusCode}, ${response.body}',
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
    BlossomAuthorization authorization = const BlossomAuthorization.none(),
    int? start,
    int? end,
  }) async {
    Exception? lastError;

    Map<String, String> headersFor(Nip01Event? authEvent) => {
          // Create range header in format "bytes=start-end"
          // If end is null, it means "until the end of the file"
          if (start != null) 'range': 'bytes=$start-${end ?? ''}',
          if (authEvent != null) 'Authorization': _authHeader(authEvent),
        };

    for (final url in serverUrls) {
      try {
        final response = await _withAuthRetry(
          authorization,
          (authEvent) => client.get(
            url: Uri.parse('$url/$sha256'),
            headers: headersFor(authEvent),
          ),
        );

        // Check for both 200 (full content) and 206 (partial content) status codes
        if (response.statusCode == 200 || response.statusCode == 206) {
          return BlobResponse(
            data: response.bodyBytes,
            mimeType: response.headers['content-type'],
            contentLength: int.tryParse(
              response.headers['content-length'] ?? '',
            ),
            contentRange: response.headers['content-range'] ?? '',
          );
        }
        lastError = Exception('HTTP ${response.statusCode}');
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
      }
    }

    throw Exception(
      'Failed to get blob from any of the servers. Last error: $lastError',
    );
  }

  @override
  Future<String> checkBlob({
    required String sha256,
    required List<String> serverUrls,
    BlossomAuthorization authorization = const BlossomAuthorization.none(),
  }) async {
    Exception? lastError;

    for (final url in serverUrls) {
      try {
        final response = await _withAuthRetry(
          authorization,
          (authEvent) => client.head(
            url: Uri.parse('$url/$sha256'),
            headers: <String, String>{
              if (authEvent != null) 'Authorization': _authHeader(authEvent),
            },
          ),
        );

        if (_isSuccessStatus(response.statusCode)) {
          return '$url/$sha256';
        }
        lastError = Exception('HTTP ${response.statusCode}');
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
      }
    }

    throw Exception(
      'Failed to check blob from any of the servers. Last error: $lastError',
    );
  }

  /// first value is whether the server supports range requests \
  /// second value is the content length of the blob in bytes
  @override
  Future<Tuple<bool, int?>> supportsRangeRequests({
    required String sha256,
    required String serverUrl,
    BlossomAuthorization authorization = const BlossomAuthorization.none(),
  }) async {
    try {
      final response = await _withAuthRetry(
        authorization,
        (authEvent) => client.head(
          url: Uri.parse('$serverUrl/$sha256'),
          headers: <String, String>{
            if (authEvent != null) 'Authorization': _authHeader(authEvent),
          },
        ),
      );

      final acceptRanges = response.headers['accept-ranges'];
      final contentLength = int.tryParse(
        response.headers['content-length'] ?? '',
      );
      return Tuple(acceptRanges?.toLowerCase() == 'bytes', contentLength);
    } catch (e) {
      return Tuple(false, null);
    }
  }

  @override
  Future<Stream<BlobResponse>> getBlobStream({
    required String sha256,
    required List<String> serverUrls,
    BlossomAuthorization authorization = const BlossomAuthorization.none(),
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
          authorization: authorization,
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
      final bytes = await getBlob(
        sha256: sha256,
        serverUrls: serverUrls,
        authorization: authorization,
      );
      return Stream.value(bytes);
    }

    return _chunkedBlobStream(
      sha256: sha256,
      serverUrl: supportedServer,
      authorization: authorization,
      contentLength: contentLength,
      chunkSize: chunkSize,
    );
  }

  /// Fetches one range at a time, as the caller reads, so a large blob is
  /// never held whole in memory.
  Stream<BlobResponse> _chunkedBlobStream({
    required String sha256,
    required String serverUrl,
    required int contentLength,
    required int chunkSize,
    BlossomAuthorization authorization = const BlossomAuthorization.none(),
  }) async* {
    int offset = 0;
    while (offset < contentLength) {
      final end = (offset + chunkSize - 1).clamp(0, contentLength - 1);
      yield await getBlob(
        sha256: sha256,
        serverUrls: [serverUrl],
        authorization: authorization,
        start: offset,
        end: end,
      );
      offset = end + 1;
    }
  }

  @override
  Future<List<BlobDescriptor>> listBlobs({
    required pubkey,
    required List<String> serverUrls,
    DateTime? since,
    DateTime? until,
    BlossomAuthorization authorization = const BlossomAuthorization.none(),
  }) async {
    Exception? lastError;

    for (final url in serverUrls) {
      try {
        final queryParams = <String, String>{
          if (since != null) 'since': '${since.millisecondsSinceEpoch ~/ 1000}',
          if (until != null) 'until': '${until.millisecondsSinceEpoch ~/ 1000}',
        };

        final response = await _withAuthRetry(
          authorization,
          (authEvent) => client.get(
            url: Uri.parse('$url/list/$pubkey')
                .replace(queryParameters: queryParams),
            headers: <String, String>{
              if (authEvent != null) 'Authorization': _authHeader(authEvent),
            },
          ),
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
      'Failed to list blobs from all servers. Last error: $lastError',
    );
  }

  @override
  Future<List<BlobDeleteResult>> deleteBlob({
    required String sha256,
    required List<String> serverUrls,
    required BlossomAuthorization authorization,
  }) async {
    final results = await Future.wait(
      serverUrls.map(
        (url) => _deleteFromServer(
          serverUrl: url,
          sha256: sha256,
          authorization: authorization,
        ),
      ),
    );
    return results;
  }

  Future<BlobDeleteResult> _deleteFromServer({
    required String serverUrl,
    required String sha256,
    required BlossomAuthorization authorization,
  }) async {
    try {
      final response = await _withAuthRetry(
        authorization,
        (authEvent) => client.delete(
          url: Uri.parse('$serverUrl/$sha256'),
          headers: {
            if (authEvent != null) 'Authorization': _authHeader(authEvent),
          },
        ),
      );

      return BlobDeleteResult(
        serverUrl: serverUrl,
        success: _isSuccessStatus(response.statusCode),
        error: !_isSuccessStatus(response.statusCode)
            ? 'HTTP ${response.statusCode}'
            : null,
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
  Future<BlobResponse> directDownload({required Uri url}) async {
    final response = await client.get(url: url);
    return BlobResponse(
      data: response.bodyBytes,
      mimeType: response.headers['content-type'],
      contentLength: int.tryParse(response.headers['content-length'] ?? ''),
      contentRange: response.headers['content-range'] ?? '',
    );
  }

  @override
  Future<void> directDownloadToFile({
    required Uri url,
    required String outputPath,
  }) async {
    final response = client.getStream(url: url);
    await fileIO.writeFileStream(
      outputPath,
      response.map((chunk) => Uint8List.fromList(chunk)),
    );
  }

  @override
  Future<void> downloadBlobToFile({
    required String sha256,
    required String outputPath,
    required List<String> serverUrls,
    BlossomAuthorization authorization = const BlossomAuthorization.none(),
  }) async {
    // Use the streaming method to download and write to file
    final stream = await getBlobStream(
      sha256: sha256,
      serverUrls: serverUrls,
      authorization: authorization,
    );

    await fileIO.writeFileStream(
      outputPath,
      stream.map((response) => response.data),
    );
  }

  @override
  Future<int> report({
    required String serverUrl,
    required String sha256,
    required Nip01Event reportEvent,
  }) async {
    final String myBody = jsonEncode(
      Nip01EventModel.fromEntity(reportEvent).toJson(),
    );

    final response = await client.put(
      url: Uri.parse('$serverUrl/report'),
      body: myBody, //reportEvent.toBase64(),
      headers: {'Content-Type': 'application/json'},
    );
    return response.statusCode;
  }

  @override
  Stream<FileHashProgress> computeFileHash(String filePath) {
    return fileIO.computeFileHash(filePath);
  }
}
