import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_webrtc_zxing/flutter_webrtc_zxing.dart' as zxing;
import 'package:image/image.dart' as image;

/// Decodes original camera pixels without the ReaderWidget's 768px resize and
/// central crop, which discard detail and finder patterns in dense offer QRs.
/// Called through compute so image conversion and detection stay off the UI.
String? decodeLinuxQrFrame(Uint8List bytes) {
  final frame = image.decodeImage(bytes);
  if (frame == null) return null;
  final result = zxing.zx.readBarcode(
    frame.getBytes(order: image.ChannelOrder.rgb),
    zxing.DecodeParams(
      width: frame.width,
      height: frame.height,
      imageFormat: zxing.ImageFormat.rgb,
      format: zxing.Format.qrCode,
      tryHarder: true,
      tryRotate: true,
      tryInverted: true,
      tryDownscale: true,
    ),
  );
  return result.isValid ? result.text : null;
}

Future<String?> decodeWebQrFrame(Uint8List bytes) async {
  final result = await zxing.zx.processWebRtcFrame(
    bytes,
    zxing.DecodeParams(
      format: zxing.Format.qrCode,
      tryHarder: true,
      tryRotate: true,
      tryInverted: true,
      tryDownscale: true,
    ),
    cropPercent: 0,
  );
  return result.isValid ? result.text : null;
}

/// Linux/Chrome camera preview and sequential full-resolution QR decoding.
class FullFrameQrScanner extends StatefulWidget {
  final ValueChanged<String> onScan;
  final ValueChanged<Exception> onError;

  const FullFrameQrScanner({
    super.key,
    required this.onScan,
    required this.onError,
  });

  @override
  State<FullFrameQrScanner> createState() => _FullFrameQrScannerState();
}

class _FullFrameQrScannerState extends State<FullFrameQrScanner>
    with WidgetsBindingObserver {
  RTCVideoRenderer? _renderer;
  Future<void>? _session;
  int _generation = 0;
  int _decodeAttempts = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _restart();
  }

  bool _isCurrent(int generation) => mounted && generation == _generation;

  void _restart() {
    final generation = ++_generation;
    final previous = _session;
    _session = () async {
      // Wait for capture/decoding and camera release before opening again.
      await previous;
      if (_isCurrent(generation)) await _runCamera(generation);
    }();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _restart();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      ++_generation;
    }
  }

  Future<void> _runCamera(int generation) async {
    final renderer = RTCVideoRenderer();
    MediaStream? stream;
    try {
      if (kIsWeb) {
        await zxing.zx.startCameraProcessing();
        if (kDebugMode) debugPrint('[web-qr] WASM decoder ready');
      } else {
        await WebRTC.initialize();
      }
      if (!_isCurrent(generation)) return;
      await renderer.initialize();
      if (!_isCurrent(generation)) return;
      stream = await navigator.mediaDevices.getUserMedia({
        'audio': false,
        'video': {
          'width': {'ideal': 1920},
          'height': {'ideal': 1080},
          'frameRate': {'ideal': 15},
          'facingMode': 'environment',
        },
      });
      if (!_isCurrent(generation)) return;
      final tracks = stream.getVideoTracks();
      if (tracks.isEmpty) throw StateError('Camera has no video track');
      final firstFrame = Completer<void>();
      renderer.onFirstFrameRendered = () {
        if (!firstFrame.isCompleted) firstFrame.complete();
      };
      renderer.srcObject = stream;
      setState(() => _renderer = renderer);
      if (kIsWeb) {
        // Chrome's WebRTC renderer does not reliably invoke
        // onFirstFrameRendered. Wait for dimensions, but let captureFrame
        // proceed even when they remain unavailable.
        for (var attempt = 0;
            attempt < 20 && renderer.videoWidth == 0 && _isCurrent(generation);
            attempt++) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
      } else {
        await firstFrame.future.timeout(const Duration(seconds: 10));
      }
      if (!_isCurrent(generation)) return;
      if (kDebugMode) {
        debugPrint('QR camera: ${renderer.videoWidth}x'
            '${renderer.videoHeight}; full-frame decoding');
      }

      while (_isCurrent(generation)) {
        final frame = await tracks.first.captureFrame();
        if (!_isCurrent(generation)) break;
        final bytes = frame.asUint8List();
        _decodeAttempts++;
        if (kDebugMode && (_decodeAttempts == 1 || _decodeAttempts % 10 == 0)) {
          debugPrint('[${kIsWeb ? 'web' : 'linux'}-qr] decode attempt '
              '$_decodeAttempts; frame=${bytes.length} bytes');
        }
        final value = kIsWeb
            ? await decodeWebQrFrame(bytes)
            : await compute(decodeLinuxQrFrame, bytes);
        if (!_isCurrent(generation)) break;
        if (value != null && value.trim().isNotEmpty) {
          if (kDebugMode) {
            // QR payloads can contain wallet credentials; never log contents.
            debugPrint('[qr] decoded ${value.length} characters; '
                'returning scan result');
          }
          widget.onScan(value);
          break;
        }
        // No overlapping captures or queued decodes on slower machines.
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
    } catch (error) {
      if (_isCurrent(generation)) {
        widget.onError(error is Exception ? error : Exception('$error'));
      }
    } finally {
      if (identical(_renderer, renderer)) {
        if (mounted) {
          setState(() => _renderer = null);
        } else {
          _renderer = null;
        }
      }
      if (stream != null) {
        for (final track in stream.getTracks()) {
          await track.stop();
        }
        await stream.dispose();
      }
      await renderer.dispose();
      if (kIsWeb) zxing.zx.stopCameraProcessing();
    }
  }

  @override
  void dispose() {
    ++_generation;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final renderer = _renderer;
    return renderer == null
        ? const ColoredBox(color: Colors.black)
        : RTCVideoView(
            renderer,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
          );
  }
}
