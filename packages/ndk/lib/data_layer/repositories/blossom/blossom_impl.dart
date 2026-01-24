import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:rxdart/rxdart.dart';

import '../../../domain_layer/entities/blossom_blobs.dart';
import '../../../domain_layer/entities/nip_01_event.dart';
import '../../../domain_layer/entities/tuple.dart';
import '../../../domain_layer/repositories/blossom.dart';
import '../../data_sources/http_request.dart';
import '../../io/file_io.dart';
import '../../io/file_io_platform.dart';
import '../../models/nip_01_event_model.dart';

/// Progress information for blob uploads
class BlobUploadProgress {
  final String currentServer;
  final int sentBytes;
  final int totalBytes;
  final List<BlobUploadResult> completedUploads;
  final bool isComplete;

  BlobUploadProgress({
    required this.currentServer,
    required this.sentBytes,
    required this.totalBytes,
    required this.completedUploads,
    this.isComplete = false,
  });

  double get progress => totalBytes > 0 ? sentBytes / totalBytes : 0;
  double get percentage => progress * 100;
}

class BlossomRepositoryImpl implements BlossomRepository {
  final HttpRequestDS client;
  final FileIO fileIO;

  BlossomRepositoryImpl({
    required this.client,
    FileIO? fileIO,
  }) : fileIO = fileIO ?? FileIONative();

  @override
  Stream<BlobUploadProgress> uploadBlob({
    required Stream<List<int>> Function() dataStreamFactory,
    required int contentLength,
    required Nip01Event authorization,
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
    required Nip01Event authorization,
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
    required Nip01Event authorization,
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
          dataStream: dataStreamFactory(), // Create new stream for each attempt
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
          );

          if (progress.isComplete && progress.response != null) {
            final result = BlobUploadResult(
              serverUrl: serverUrl,
              success: true,
              descriptor:
                  BlobDescriptor.fromJson(jsonDecode(progress.response!.body)),
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

    // Emit final progress
    yield BlobUploadProgress(
      currentServer: '',
      sentBytes: contentLength,
      totalBytes: contentLength,
      completedUploads: results,
      isComplete: true,
    );
  }

  Stream<BlobUploadProgress> _uploadToAllServers({
    required Stream<List<int>> Function() dataStreamFactory,
    required int contentLength,
    required List<String> serverUrls,
    required Nip01Event authorization,
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
      ),
    );

    // Start all uploads simultaneously
    final uploadFutures = serverUrls.map((serverUrl) async {
      try {
        await for (final progress in _uploadToServer(
          serverUrl: serverUrl,
          dataStream: dataStreamFactory(),
          contentLength: contentLength,
          contentType: contentType,
          authorization: authorization,
          mediaOptimisation: mediaOptimisation,
        )) {
          // Emit intermediate per-server progress updates
          if (!progress.isComplete) {
            progressSubject.add(BlobUploadProgress(
              currentServer: serverUrl,
              sentBytes: progress.sentBytes,
              totalBytes: progress.totalBytes,
              completedUploads: List.from(results),
            ));
            continue;
          }
          if (progress.isComplete && progress.response != null) {
            final result = BlobUploadResult(
              serverUrl: serverUrl,
              success: true,
              descriptor:
                  BlobDescriptor.fromJson(jsonDecode(progress.response!.body)),
            );
            results.add(result);
            progressSubject.add(BlobUploadProgress(
              currentServer: serverUrl,
              sentBytes: progress.sentBytes,
              totalBytes: contentLength,
              completedUploads: List.from(results),
            ));
          } else if (progress.isComplete && progress.error != null) {
            final result = BlobUploadResult(
              serverUrl: serverUrl,
              success: false,
              error: progress.error.toString(),
            );
            results.add(result);
            progressSubject.add(BlobUploadProgress(
              currentServer: serverUrl,
              sentBytes: progress.sentBytes,
              totalBytes: contentLength,
              completedUploads: List.from(results),
            ));
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
        progressSubject.add(BlobUploadProgress(
          currentServer: serverUrl,
          sentBytes: 0,
          totalBytes: contentLength,
          completedUploads: List.from(results),
        ));
      }
    }).toList();

    // When all uploads complete, close the stream
    Future.wait(uploadFutures).then((_) async {
      await progressSubject.close();
    });

    // Forward progress updates until the subject closes
    yield* progressSubject.stream;
  }

  Stream<BlobUploadProgress> _uploadToFirstSuccess({
    required Stream<List<int>> Function() dataStreamFactory,
    required int contentLength,
    required List<String> serverUrls,
    required Nip01Event authorization,
    String? contentType,
    bool mediaOptimisation = false,
  }) async* {
    final results = <BlobUploadResult>[];

    for (final url in serverUrls) {
      try {
        await for (final progress in _uploadToServer(
          serverUrl: url,
          dataStream: dataStreamFactory(),
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
          );

          if (progress.isComplete && progress.response != null) {
            final result = BlobUploadResult(
              serverUrl: url,
              success: true,
              descriptor:
                  BlobDescriptor.fromJson(jsonDecode(progress.response!.body)),
            );
            results.add(result);

            yield BlobUploadProgress(
              currentServer: url,
              sentBytes: progress.sentBytes,
              totalBytes: contentLength,
              completedUploads: results,
              isComplete: true,
            );
            return;
          } else if (progress.isComplete && progress.error != null) {
            results.add(BlobUploadResult(
              serverUrl: url,
              success: false,
              error: progress.error.toString(),
            ));
          }
        }
      } catch (e) {
        // Handle network exceptions (e.g., host lookup failures)
        results.add(BlobUploadResult(
          serverUrl: url,
          success: false,
          error: e.toString(),
        ));
      }
    }

    // All servers failed
    yield BlobUploadProgress(
      currentServer: '',
      sentBytes: 0,
      totalBytes: contentLength,
      completedUploads: results,
      isComplete: true,
    );
  }

  /// Upload a file to a server \
  /// If [mediaOptimisation] is true, the server will optimise the file for media streaming using the /media endpoint [BUD-05]
  Stream<UploadProgress> _uploadToServer({
    required String serverUrl,
    required Stream<List<int>> dataStream,
    required int contentLength,
    Nip01Event? authorization,
    String? contentType,
    bool mediaOptimisation = false,
  }) {
    final endpointUrl =
        mediaOptimisation ? '$serverUrl/media' : '$serverUrl/upload';

    return client.putStream(
      url: Uri.parse(endpointUrl),
      body: dataStream,
      headers: {
        if (contentType != null) 'Content-Type': contentType,
        if (authorization != null)
          'Authorization':
              "Nostr ${Nip01EventModel.fromEntity(authorization).toBase64()}",
        'Content-Length': '$contentLength',
      },
      contentLength: contentLength,
    );
  }

  /// Mirror a file from one server to another, based on the file URL
  Future<BlobUploadResult> _mirrorToServer({
    required String fileUrl,
    required String serverUrl,
    required String sha256,
    required Nip01Event authorization,
  }) async {
    final jsonMsg = {"url": fileUrl};

    final String myBody = jsonEncode(jsonMsg);
    try {
      // Mirror endpoint is PUT /mirror/
      final response = await client.put(
        url: Uri.parse('$serverUrl/mirror'),
        body: myBody,
        headers: {
          'Authorization':
              "Nostr ${Nip01EventModel.fromEntity(authorization).toBase64()}",
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
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

        if (authorization != null) {
          headers['Authorization'] =
              "Nostr ${Nip01EventModel.fromEntity(authorization).toBase64()}";
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

  @override
  Future<String> checkBlob({
    required String sha256,
    required List<String> serverUrls,
    Nip01Event? authorization,
  }) async {
    Exception? lastError;

    final headers = <String, String>{};

    if (authorization != null) {
      headers['Authorization'] =
          "Nostr ${Nip01EventModel.fromEntity(authorization).toBase64()}";
    }

    for (final url in serverUrls) {
      try {
        final response = await client.head(
          url: Uri.parse('$url/$sha256'),
        );

        if (response.statusCode == 200) {
          return '$url/$sha256';
        }
        lastError = Exception('HTTP ${response.statusCode}');
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
      }
    }

    throw Exception(
        'Failed to check blob from any of the servers. Last error: $lastError');
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

        final headers = <String, String>{};
        if (authorization != null) {
          headers['Authorization'] =
              "Nostr ${Nip01EventModel.fromEntity(authorization).toBase64()}";
        }

        final response = await client.get(
          url: Uri.parse('$url/list/$pubkey')
              .replace(queryParameters: queryParams),
          headers: headers,
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
          'Authorization':
              "Nostr ${Nip01EventModel.fromEntity(authorization).toBase64()}",
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

  @override
  Future<void> directDownloadToFile({
    required Uri url,
    required String outputPath,
  }) async {
    final response = client.getStream(url: url);
    await fileIO.writeFileStream(
        outputPath, response.map((chunk) => Uint8List.fromList(chunk)));
  }

  @override
  Future<void> downloadBlobToFile({
    required String sha256,
    required String outputPath,
    required List<String> serverUrls,
    Nip01Event? authorization,
  }) async {
    // Use the streaming method to download and write to file
    final stream = await getBlobStream(
      sha256: sha256,
      serverUrls: serverUrls,
      authorization: authorization,
    );

    await fileIO.writeFileStream(
        outputPath, stream.map((response) => response.data));
  }

  @override
  Future<int> report({
    required String serverUrl,
    required String sha256,
    required Nip01Event reportEvent,
  }) async {
    final String myBody =
        jsonEncode(Nip01EventModel.fromEntity(reportEvent).toJson());

    final response = await client.put(
      url: Uri.parse('$serverUrl/report'),
      body: myBody, //reportEvent.toBase64(),
      headers: {
        'Content-Type': 'application/json',
      },
    );
    return response.statusCode;
  }
}
