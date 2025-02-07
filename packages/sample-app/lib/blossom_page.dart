import 'package:flutter/material.dart';
import 'package:ndk/ndk.dart';

class BlossomPage extends StatefulWidget {
  final Ndk ndk;

  BlossomPage({Key? key, required this.ndk}) : super(key: key);

  @override
  State<BlossomPage> createState() => _BlossomPageState();
}

class _BlossomPageState extends State<BlossomPage> {
  BlobResponse? _blobResponse;
  bool _isLoading = false;
  String _error = '';

  Future<void> _downloadImage() async {
    setState(() {
      _isLoading = true;
      _error = '';
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
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Blossom Page'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (_isLoading)
                Center(child: CircularProgressIndicator())
              else if (_error.isNotEmpty)
                Text('Error: $_error', style: TextStyle(color: Colors.red))
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
                      Text('Size: ${_blobResponse!.contentLength} bytes'),
                  ],
                )
              else
                Text('No image downloaded yet'),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _downloadImage,
                child: Text('Download Image'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _blobResponse = null;
                  });
                },
                child: Text('clear'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
