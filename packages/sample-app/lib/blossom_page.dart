import 'package:flutter/material.dart';
import 'package:ndk/ndk.dart';
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
          'https://blossom.f7z.io',
          "https://nostr.download",
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Blossom Media Page'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Image Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Text('Image',
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
                      Text('Video',
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
            ],
          ),
        ),
      ),
    );
  }
}
