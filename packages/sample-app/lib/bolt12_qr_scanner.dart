import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ndk/entities.dart';
import 'package:ndk_flutter/l10n/app_localizations.dart' as ndk_l10n;

Future<String?> scanBolt12Input(BuildContext context) {
  return showDialog<String?>(
    context: context,
    builder: (context) => const _Bolt12QrScannerDialog(),
  );
}

class _Bolt12QrScannerDialog extends StatefulWidget {
  const _Bolt12QrScannerDialog();

  @override
  State<_Bolt12QrScannerDialog> createState() => _Bolt12QrScannerDialogState();
}

class _Bolt12QrScannerDialogState extends State<_Bolt12QrScannerDialog> {
  MobileScannerController? _controller;
  bool _hasScanned = false;
  String? _error;

  bool get _hasCamera =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    if (_hasCamera) {
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  bool _accept(String? rawValue) {
    if (rawValue == null) return false;
    final value = rawValue.trim();
    if (!Bolt12WalletProvider.isSupportedInput(value)) return false;
    _hasScanned = true;
    Navigator.of(context).pop(value);
    return true;
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    for (final barcode in capture.barcodes) {
      if (_accept(barcode.rawValue)) return;
    }
    setState(() {
      _error = ndk_l10n.AppLocalizations.of(context)!.invalidBolt12QrCode;
    });
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted || _accept(data?.text)) return;
    setState(() {
      _error = ndk_l10n.AppLocalizations.of(context)!.invalidBolt12QrCode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ndk_l10n.AppLocalizations.of(context)!;
    return Dialog(
      backgroundColor: Colors.black,
      child: SizedBox(
        width: 400,
        height: _hasCamera ? 560 : 240,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  Expanded(
                    child: Text(
                      l10n.scanBolt12QrCodeTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  if (_hasCamera)
                    MobileScanner(controller: _controller!, onDetect: _onDetect)
                  else
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          l10n.cameraNotAvailable,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                  if (_hasCamera)
                    Center(
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  if (_error != null)
                    Positioned(
                      top: 20,
                      left: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: _paste,
                icon: const Icon(Icons.paste),
                label: Text(l10n.paste),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
