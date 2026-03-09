import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:ndk/ndk.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class BlossomMediaPage extends StatefulWidget {
  final Ndk ndk;

  BlossomMediaPage({
    Key? key,
    required this.ndk,
  }) : super(key: key);

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
        _downloadError = 'No file uploaded yet to download';
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
        _downloadedFilePath = kIsWeb ? 'Downloaded to browser' : outputPath;
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Blossom Media & File Operations'),
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
                      Text('Image Demo (getBlob)',
                          style: Theme.of(context).textTheme.titleLarge),
                      SizedBox(height: 16),
                      if (_isLoadingImage)
                        Center(child: CircularProgressIndicator())
                      else if (_imageError.isNotEmpty)
                        Text('Error: $_imageError',
                            style: TextStyle(color: Colors.red))
                      else if (_blobResponse != null)
                        Column(
                          children: [
                            Image.memory(
                              _blobResponse!.data,
                              fit: BoxFit.contain,
                            ),
                            SizedBox(height: 16),
                            if (_blobResponse?.mimeType != null)
                              Text('Mime Type: ${_blobResponse!.mimeType}'),
                            if (_blobResponse?.contentLength != null)
                              Text(
                                  'Size: ${_blobResponse!.contentLength} bytes'),
                          ],
                        )
                      else
                        Text('No image downloaded yet'),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: _isLoadingImage ? null : _downloadImage,
                            child: Text('Download Image'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _blobResponse = null;
                              });
                            },
                            child: Text('Clear Image'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Video Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Text('Video Demo (checkBlob)',
                          style: Theme.of(context).textTheme.titleLarge),
                      SizedBox(height: 16),
                      if (_isLoadingVideo)
                        Center(child: CircularProgressIndicator())
                      else if (_videoError.isNotEmpty)
                        Text('Error: $_videoError',
                            style: TextStyle(color: Colors.red))
                      else if (_videoUrl != null)
                        Column(
                          children: [
                            AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Video(
                                controller: _videoController,
                              ),
                            ),
                            SizedBox(height: 16),
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
                              'Video URL: $_videoUrl',
                              style: TextStyle(fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        )
                      else
                        Text('No video loaded yet'),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed:
                                _isLoadingVideo ? null : _checkAndInitVideo,
                            child: Text('Load Video'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _player.stop();
                                _videoUrl = null;
                              });
                            },
                            child: Text('Clear Video'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Upload Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Upload File from Disk',
                          style: Theme.of(context).textTheme.titleLarge),
                      SizedBox(height: 16),
                      Text(
                        'Demonstrates uploadFromFile() method with streaming progress',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      SizedBox(height: 16),
                      if (_isUploading) ...[
                        LinearProgressIndicator(value: _uploadProgress),
                        SizedBox(height: 8),
                        Text(
                            'Uploading: ${(_uploadProgress * 100).toStringAsFixed(1)}%'),
                      ] else if (_uploadError.isNotEmpty)
                        Text('Error: $_uploadError',
                            style: TextStyle(color: Colors.red))
                      else if (_uploadedSha256 != null) ...[
                        Text('✓ Upload successful!',
                            style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text('SHA256: $_uploadedSha256',
                            style: TextStyle(
                                fontSize: 12, fontFamily: 'monospace')),
                        SizedBox(height: 4),
                        Text('URL: $_uploadedUrl',
                            style: TextStyle(fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ] else
                        Text('No file uploaded yet'),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isUploading ? null : _pickAndUploadFile,
                            icon: Icon(Icons.upload_file),
                            label: Text('Pick & Upload File'),
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
                              child: Text('Clear'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Download Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Download File to Disk',
                          style: Theme.of(context).textTheme.titleLarge),
                      SizedBox(height: 16),
                      Text(
                        'Demonstrates downloadToFile() method (saves directly to disk)',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      SizedBox(height: 16),
                      if (_isDownloading)
                        Center(child: CircularProgressIndicator())
                      else if (_downloadError.isNotEmpty)
                        Text('Error: $_downloadError',
                            style: TextStyle(color: Colors.red))
                      else if (_downloadedFilePath != null) ...[
                        Text('✓ Download successful!',
                            style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text('Saved to: $_downloadedFilePath',
                            style: TextStyle(fontSize: 12),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis),
                      ] else
                        Text('No file downloaded yet'),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: (_isDownloading || _uploadedUrl == null)
                                ? null
                                : _downloadFile,
                            icon: Icon(Icons.download),
                            label: Text('Download Uploaded File'),
                          ),
                          if (_downloadedFilePath != null)
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _downloadedFilePath = null;
                                  _downloadError = '';
                                });
                              },
                              child: Text('Clear'),
                            ),
                        ],
                      ),
                      if (_uploadedUrl == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Upload a file first to enable download',
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
