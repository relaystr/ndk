import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:ndk/ndk.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:ndk_demo/l10n/app_localizations_context.dart';

class BlossomMediaPage extends StatefulWidget {
  final Ndk ndk;

  const BlossomMediaPage({
    super.key,
    required this.ndk,
  });

  @override
  State<BlossomMediaPage> createState() => _BlossomMediaPageState();
}

class _BlossomMediaPageState extends State<BlossomMediaPage> {
  // Upload state
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _uploadError = '';
  String? _uploadedSha256;
  String? _uploadedUrl;

  // Download state
  bool _isDownloading = false;
  String _downloadError = '';
  String? _downloadedFilePath;

  // Image/Video demo state
  BlobResponse? _blobResponse;
  late final Player _player;
  late final VideoController _videoController;
  bool _isLoadingImage = false;
  bool _isLoadingVideo = false;
  String _imageError = '';
  String _videoError = '';
  String? _videoUrl;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _videoController = VideoController(_player);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _downloadImage() async {
    setState(() {
      _isLoadingImage = true;
      _imageError = '';
    });

    try {
      final response = await widget.ndk.blossom.getBlob(
        sha256:
            'fc0066f8d123cf9cbe2bd95e3439cd91b5401e0560dab65a49695ab932ffec59',
        serverUrls: [
          // 'https://blossom.f7z.io',
          "https://nostr.download",
          "https://cdn.hzrd149.com"
        ],
        useAuth: false,
      );

      setState(() {
        _blobResponse = response;
      });
    } catch (e) {
      setState(() {
        _imageError = e.toString();
      });
    } finally {
      setState(() {
        _isLoadingImage = false;
      });
    }
  }

  Future<void> _checkAndInitVideo() async {
    setState(() {
      _isLoadingVideo = true;
      _videoError = '';
    });

    try {
      final url = await widget.ndk.blossom.checkBlob(
        sha256:
            '45c8bafeb9a53df7f491198d2e71529701bcf1cd51805782089fac1d32869f9b',
        serverUrls: [
          'https://blossom.f7z.io',
          "https://nostr.download",
          "https://cdn.hzrd149.com"
        ],
        useAuth: false,
      );

      setState(() {
        _videoUrl = url;
      });

      // Play the video
      await _player.open(Media(url));
    } catch (e) {
      setState(() {
        _videoError = e.toString();
      });
    } finally {
      setState(() {
        _isLoadingVideo = false;
      });
    }
  }

  Future<void> _pickAndUploadFile() async {
    // Pick a file
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result == null) {
      return;
    }

    // On web, path is null but bytes are available
    final file = result.files.single;
    if (!kIsWeb && file.path == null) {
      return;
    }

    final filePath = file.path ?? file.name;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadError = '';
      _uploadedSha256 = null;
      _uploadedUrl = null;
    });

    try {
      // Use the uploadFromFile method with stream
      final stream = widget.ndk.files.uploadFromFile(
        filePath: filePath,
        serverUrls: ["https://nostr.download", "https://cdn.hzrd149.com"],
        strategy: UploadStrategy.mirrorAfterSuccess,
        serverMediaOptimisation: false,
      );

      await for (final progress in stream) {
        setState(() {
          _uploadProgress = progress.progress;
        });

        // Check if upload is complete
        if (progress.isComplete) {
          final successfulUploads = progress.completedUploads
              .where((r) => r.success && r.descriptor != null)
              .toList();

          if (successfulUploads.isNotEmpty) {
            final descriptor = successfulUploads.first.descriptor!;
            setState(() {
              _uploadedSha256 = descriptor.sha256;
              _uploadedUrl = descriptor.url;
            });
          }
        }
      }
    } catch (e) {
      setState(() {
        _uploadError = e.toString();
      });
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _downloadFile() async {
    if (_uploadedUrl == null && _uploadedSha256 == null) {
      setState(() {
        _downloadError = context.l10n.blossomNoUploadedFileToDownload;
      });
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadError = '';
      _downloadedFilePath = null;
    });

    try {
      String outputPath;

      if (kIsWeb) {
        // On web, use the filename as path (triggers browser download)
        outputPath = 'downloaded_${_uploadedSha256 ?? 'file'}';
      } else {
        // On native platforms, get the documents directory
        final directory = await getApplicationDocumentsDirectory();
        outputPath =
            '${directory.path}/downloaded_${_uploadedSha256 ?? 'file'}';
      }

      // Use the downloadToFile method
      await widget.ndk.files.downloadToFile(
        url: _uploadedUrl!,
        outputPath: outputPath,
        useAuth: false,
        serverUrls: ["https://nostr.download", "https://cdn.hzrd149.com"],
      );

      setState(() {
        _downloadedFilePath =
            kIsWeb ? context.l10n.blossomDownloadedToBrowser : outputPath;
      });
    } catch (e) {
      setState(() {
        _downloadError = e.toString();
      });
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.blossomPageTitle),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Text(l10n.blossomImageDemoTitle,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      if (_isLoadingImage)
                        const Center(child: CircularProgressIndicator())
                      else if (_imageError.isNotEmpty)
                        Text(l10n.errorLabel(_imageError),
                            style: const TextStyle(color: Colors.red))
                      else if (_blobResponse != null)
                        Column(
                          children: [
                            Image.memory(
                              _blobResponse!.data,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 16),
                            if (_blobResponse?.mimeType != null)
                              Text(l10n
                                  .blossomMimeType(_blobResponse!.mimeType!)),
                            if (_blobResponse?.contentLength != null)
                              Text(l10n.blossomFileSizeBytes(
                                  _blobResponse!.contentLength.toString())),
                          ],
                        )
                      else
                        Text(l10n.blossomNoImageYet),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: _isLoadingImage ? null : _downloadImage,
                            child: Text(l10n.blossomDownloadImage),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _blobResponse = null;
                              });
                            },
                            child: Text(l10n.blossomClearImage),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Video Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Text(l10n.blossomVideoDemoTitle,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      if (_isLoadingVideo)
                        const Center(child: CircularProgressIndicator())
                      else if (_videoError.isNotEmpty)
                        Text(l10n.errorLabel(_videoError),
                            style: const TextStyle(color: Colors.red))
                      else if (_videoUrl != null)
                        Column(
                          children: [
                            AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Video(
                                controller: _videoController,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: StreamBuilder(
                                    stream: _player.stream.playing,
                                    builder: (context, snapshot) {
                                      final playing = snapshot.data ?? false;
                                      return Icon(
                                        playing
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                      );
                                    },
                                  ),
                                  onPressed: () {
                                    _player.playOrPause();
                                  },
                                ),
                              ],
                            ),
                            Text(
                              l10n.blossomVideoUrl(_videoUrl!),
                              style: const TextStyle(fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        )
                      else
                        Text(l10n.blossomNoVideoYet),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed:
                                _isLoadingVideo ? null : _checkAndInitVideo,
                            child: Text(l10n.blossomLoadVideo),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _player.stop();
                                _videoUrl = null;
                              });
                            },
                            child: Text(l10n.blossomClearVideo),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Upload Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.blossomUploadTitle,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      Text(
                        l10n.blossomUploadDescription,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      if (_isUploading) ...[
                        LinearProgressIndicator(value: _uploadProgress),
                        const SizedBox(height: 8),
                        Text(l10n.blossomUploadingProgress(
                            (_uploadProgress * 100).toStringAsFixed(1))),
                      ] else if (_uploadError.isNotEmpty)
                        Text(l10n.errorLabel(_uploadError),
                            style: const TextStyle(color: Colors.red))
                      else if (_uploadedSha256 != null) ...[
                        Text(l10n.blossomUploadSuccess,
                            style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(l10n.blossomSha256(_uploadedSha256!),
                            style: const TextStyle(
                                fontSize: 12, fontFamily: 'monospace')),
                        const SizedBox(height: 4),
                        Text(l10n.blossomUrl(_uploadedUrl!),
                            style: const TextStyle(fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ] else
                        Text(l10n.blossomNoUploadedFileYet),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isUploading ? null : _pickAndUploadFile,
                            icon: const Icon(Icons.upload_file),
                            label: Text(l10n.blossomPickAndUploadFile),
                          ),
                          if (_uploadedSha256 != null)
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _uploadedSha256 = null;
                                  _uploadedUrl = null;
                                  _uploadError = '';
                                });
                              },
                              child: Text(l10n.clear),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Download Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.blossomDownloadTitle,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      Text(
                        l10n.blossomDownloadDescription,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      if (_isDownloading)
                        const Center(child: CircularProgressIndicator())
                      else if (_downloadError.isNotEmpty)
                        Text(l10n.errorLabel(_downloadError),
                            style: const TextStyle(color: Colors.red))
                      else if (_downloadedFilePath != null) ...[
                        Text(l10n.downloadSuccess,
                            style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(l10n.blossomSavedTo(_downloadedFilePath!),
                            style: const TextStyle(fontSize: 12),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis),
                      ] else
                        Text(l10n.blossomNoDownloadedFileYet),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: (_isDownloading || _uploadedUrl == null)
                                ? null
                                : _downloadFile,
                            icon: const Icon(Icons.download),
                            label: Text(l10n.blossomDownloadUploadedFile),
                          ),
                          if (_downloadedFilePath != null)
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _downloadedFilePath = null;
                                  _downloadError = '';
                                });
                              },
                              child: Text(l10n.clear),
                            ),
                        ],
                      ),
                      if (_uploadedUrl == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            l10n.blossomUploadFirstToEnableDownload,
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
