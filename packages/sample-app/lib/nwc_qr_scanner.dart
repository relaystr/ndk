import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_flutter/l10n/app_localizations.dart' as ndk_l10n;

Future<String?> scanNwcUri(BuildContext context) {
  return showDialog<String?>(
    context: context,
    builder: (context) => const _NwcQrScannerDialog(),
  );
}

class _NwcQrScannerDialog extends StatefulWidget {
  const _NwcQrScannerDialog();

  @override
  State<_NwcQrScannerDialog> createState() => _NwcQrScannerDialogState();
}

class _NwcQrScannerDialogState extends State<_NwcQrScannerDialog> {
  MobileScannerController? _scannerController;
  bool _hasScanned = false;
  String? _errorMessage;

  bool get _hasCamera =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    if (_hasCamera) {
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
      );
    }
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_hasScanned) return;

    final l10n = ndk_l10n.AppLocalizations.of(context)!;
    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue?.trim();
      if (rawValue == null || rawValue.isEmpty) continue;

      if (rawValue.startsWith(Nwc.kNWCProtocolPrefix)) {
        setState(() => _hasScanned = true);
        Navigator.of(context).pop(rawValue);
        return;
      }

      setState(() {
        _errorMessage = l10n.invalidNwcQrCode;
      });
    }
  }

  Future<void> _pasteFromClipboard() async {
    final l10n = ndk_l10n.AppLocalizations.of(context)!;
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    final text = clipboardData?.text?.trim();

    if (!mounted) return;
    if (text != null && text.startsWith(Nwc.kNWCProtocolPrefix)) {
      Navigator.of(context).pop(text);
      return;
    }

    setState(() {
      _errorMessage = l10n.invalidNwcUri;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ndk_l10n.AppLocalizations.of(context)!;
    final hasCamera = _hasCamera;

    return Dialog(
      backgroundColor: Colors.black,
      child: SizedBox(
        width: 400,
        height: hasCamera ? 560 : 220,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  Expanded(
                    child: Text(
                      l10n.scanNwcQrCodeTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            if (hasCamera)
              Expanded(
                child: Stack(
                  children: [
                    MobileScanner(
                      controller: _scannerController!,
                      onDetect: _onBarcodeDetected,
                    ),
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
                    if (_errorMessage != null) _buildErrorMessage(),
                    if (_hasScanned)
                      Container(
                        color: Colors.black.withValues(alpha: 0.7),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                  ],
                ),
              )
            else
              Expanded(
                child: Stack(
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          l10n.cameraNotAvailable,
                          style: const TextStyle(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    if (_errorMessage != null) _buildErrorMessage(),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasCamera) ...[
                    Text(
                      l10n.scanNwcInstructions,
                      style: const TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                  ],
                  ElevatedButton.icon(
                    onPressed: _pasteFromClipboard,
                    icon: const Icon(Icons.paste),
                    label: Text(l10n.paste),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Positioned(
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
          _errorMessage!,
          style: const TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
