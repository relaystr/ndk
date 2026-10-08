import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ndk_flutter/ndk_flutter.dart';
import 'package:ndk_flutter/l10n/app_localizations.dart' as ndk_l10n;

/// Builds only the camera preview/decoder used by the wallet input dialogs.
///
/// Report decoded text through [onScan] and camera failures through [onError].
/// The widget must release camera resources when disposed. NDK removes it while
/// another input dialog or connection status is displayed and recreates it when
/// scanning resumes. No camera package is required by ndk_flutter.
typedef WalletQrScannerBuilder =
    Widget Function(
      BuildContext context,
      ValueChanged<String> onScan,
      ValueChanged<Object> onError,
    );

/// Opens the shared scanner, manual input, wallet and Cashu mint chooser UI.
/// Without [qrScannerBuilder], all non-camera input methods remain available.
Future<WalletInputScanResult?> showWalletInputDialog(
  BuildContext context,
  WalletInputScannerConfiguration configuration, {
  WalletQrScannerBuilder? qrScannerBuilder,
}) {
  return showDialog<WalletInputScanResult>(
    context: context,
    builder: (_) => _WalletQrScannerScope(
      builder: qrScannerBuilder,
      child: _WalletQrScannerDialog(configuration: configuration),
    ),
  );
}

class _WalletQrScannerScope extends InheritedWidget {
  final WalletQrScannerBuilder? builder;

  const _WalletQrScannerScope({required this.builder, required super.child});

  static WalletQrScannerBuilder? of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_WalletQrScannerScope>()
      ?.builder;

  @override
  bool updateShouldNotify(_WalletQrScannerScope oldWidget) =>
      builder != oldWidget.builder;
}

// Dialog routes do not inherit widgets from the launching route. Carry the
// camera adapter into every nested manual input, wallet and QR dialog.
Future<T?> _showWalletDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  final scannerBuilder = _WalletQrScannerScope.of(context);
  return showDialog<T>(
    context: context,
    builder: (_) => _WalletQrScannerScope(
      builder: scannerBuilder,
      child: Builder(builder: builder),
    ),
  );
}

class _WalletQrScannerDialog extends StatefulWidget {
  final WalletInputScannerConfiguration configuration;

  const _WalletQrScannerDialog({required this.configuration});

  @override
  State<_WalletQrScannerDialog> createState() => _WalletQrScannerDialogState();
}

class _WalletQrScannerDialogState extends State<_WalletQrScannerDialog> {
  bool _hasScanned = false;
  bool _cameraPaused = false;
  String? _errorMessage;
  bool _closingAfterSuccess = false;

  @override
  void initState() {
    super.initState();
    widget.configuration.connectionState.addListener(_onConnectionStateChanged);
    if (widget.configuration.openWalletChooserInitially ||
        widget.configuration.openCashuMintChooserInitially) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _chooseWallet();
      });
    }
  }

  @override
  void dispose() {
    widget.configuration.connectionState.removeListener(
      _onConnectionStateChanged,
    );
    super.dispose();
  }

  void _onConnectionStateChanged() {
    if (!mounted) return;
    final state = widget.configuration.connectionState.value;
    setState(() {});
    if (state.phase == WalletConnectionPhase.connected &&
        !_closingAfterSuccess) {
      _closingAfterSuccess = true;
      final scannerRoute = ModalRoute.of(context);
      if (scannerRoute != null) {
        _closeAfterSuccessWhenCurrent(
          scannerRoute,
          const Duration(milliseconds: 1100),
        );
      }
    }
  }

  void _closeAfterSuccessWhenCurrent(
    ModalRoute<dynamic> scannerRoute,
    Duration delay,
  ) {
    Future<void>.delayed(delay, () {
      if (!mounted || !scannerRoute.isActive) return;
      if (!scannerRoute.isCurrent) {
        _closeAfterSuccessWhenCurrent(
          scannerRoute,
          const Duration(milliseconds: 100),
        );
        return;
      }
      Navigator.of(
        context,
      ).pop(const WalletInputScanResult.connectionStarted());
    });
  }

  void _onScan(String value) {
    final normalized = value.trim();
    if (!mounted || _hasScanned || _cameraPaused || normalized.isEmpty) return;
    setState(() => _hasScanned = true);
    Navigator.of(context).pop(WalletInputScanResult.value(normalized));
  }

  void _onCameraError(Object error) {
    if (!mounted || _errorMessage == error.toString()) return;
    setState(() => _errorMessage = error.toString());
  }

  Future<void> _openManualInput() async {
    await _showManualInput();
  }

  Future<void> _showManualInput({
    String initialValue = '',
    bool nwcOnly = false,
  }) async {
    if (mounted) {
      setState(() => _cameraPaused = true);
    }
    if (!mounted) return;
    final result = await _showWalletDialog<_ManualWalletInputResult>(
      context: context,
      builder: (_) => _ManualWalletInputDialog(
        initialValue: initialValue,
        supportedInputDescription:
            widget.configuration.supportedInputDescription,
        nwcOnly: nwcOnly,
      ),
    );

    if (!mounted) return;
    if (result == null) {
      setState(() => _cameraPaused = false);
      return;
    }
    if (result.connectionStarted) {
      Navigator.of(
        context,
      ).pop(const WalletInputScanResult.connectionStarted());
      return;
    }
    final value = result.value?.trim();
    if (value == null || value.isEmpty) return;
    Navigator.of(
      context,
    ).pop(WalletInputScanResult.value(value, manuallyEntered: true));
  }

  Future<void> _chooseWallet() async {
    if (mounted) {
      setState(() => _cameraPaused = true);
    }
    if (!mounted) return;
    final result = await _showWalletDialog<WalletInputScanResult>(
      context: context,
      builder: (_) => _WalletChooserDialog(configuration: widget.configuration),
    );
    if (!mounted) return;
    if (result == null) {
      if (mounted) {
        setState(() => _cameraPaused = false);
      }
      return;
    }
    if (!result.connectionStarted) Navigator.of(context).pop(result);
  }

  Future<void> _retryConnection() async {
    await widget.configuration.retryPendingConnection();
  }

  Future<void> _chooseOtherWallet() async {
    widget.configuration.cancelPendingConnection();
    await _chooseWallet();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ndk_l10n.AppLocalizations.of(context)!;
    final scannerBuilder = _WalletQrScannerScope.of(context);
    final hasCamera = scannerBuilder != null;

    final connectionState = widget.configuration.connectionState.value;
    return Dialog(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          SizedBox(
            width: 400,
            height: hasCamera ? 680 : 520,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 48),
                      Expanded(
                        child: Text(
                          l10n.scanWalletQrCode,
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
                        if (_cameraPaused ||
                            connectionState.phase != WalletConnectionPhase.idle)
                          const ColoredBox(color: Colors.black)
                        else
                          scannerBuilder(context, _onScan, _onCameraError),
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
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
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
                      Text(
                        widget.configuration.supportedInputDescription,
                        style: const TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _hasScanned ? null : _openManualInput,
                              icon: const Icon(Icons.paste),
                              label: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(l10n.pasteOrEnter),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(48),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _hasScanned ? null : _chooseWallet,
                              icon: const Icon(Icons.account_balance_wallet),
                              label: Text(l10n.chooseWallet),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white38),
                                minimumSize: const Size.fromHeight(48),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (connectionState.phase != WalletConnectionPhase.idle)
            Positioned.fill(
              child: _ConnectionStatusOverlay(
                state: connectionState,
                onRetry: _retryConnection,
                onChooseOtherWallet: _chooseOtherWallet,
                onCancel: widget.configuration.cancelPendingConnection,
              ),
            ),
        ],
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

class _ConnectionStatusOverlay extends StatelessWidget {
  final WalletConnectionState state;
  final Future<void> Function() onRetry;
  final Future<void> Function() onChooseOtherWallet;
  final VoidCallback onCancel;

  const _ConnectionStatusOverlay({
    required this.state,
    required this.onRetry,
    required this.onChooseOtherWallet,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = ndk_l10n.AppLocalizations.of(context)!;
    final failed = state.phase == WalletConnectionPhase.failed;
    final connected = state.phase == WalletConnectionPhase.connected;
    final walletName = state.walletName ?? l10n.unknownWalletType;

    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.94),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (connected)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.4, end: 1),
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOutBack,
                  builder: (context, scale, child) =>
                      Transform.scale(scale: scale, child: child),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.greenAccent,
                    size: 88,
                  ),
                )
              else if (failed)
                const Icon(
                  Icons.error_outline,
                  color: Colors.redAccent,
                  size: 72,
                )
              else
                const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 24),
              Text(
                connected
                    ? l10n.walletConnectionConnected(walletName)
                    : failed
                    ? l10n.walletConnectionFailed(walletName)
                    : state.phase == WalletConnectionPhase.awaitingReturn
                    ? l10n.walletConnectionFinishIn(walletName)
                    : l10n.walletConnectionConnecting(walletName),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              if (failed) ...[
                const SizedBox(height: 12),
                if (state.error case final error?)
                  Text(
                    error,
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onRetry,
                    child: Text(l10n.retry),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onChooseOtherWallet,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38),
                    ),
                    child: Text(l10n.chooseAnotherWallet),
                  ),
                ),
              ] else if (!connected) ...[
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(l10n.cancel),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ManualWalletInputDialog extends StatefulWidget {
  final String initialValue;
  final String supportedInputDescription;
  final bool nwcOnly;
  final Future<void> Function()? connectWalletApp;

  const _ManualWalletInputDialog({
    required this.initialValue,
    required this.supportedInputDescription,
    required this.nwcOnly,
    this.connectWalletApp,
  });

  @override
  State<_ManualWalletInputDialog> createState() =>
      _ManualWalletInputDialogState();
}

class _ManualWalletInputDialogState extends State<_ManualWalletInputDialog> {
  late final TextEditingController _controller;
  WalletInputKind? _kind;
  bool _isLaunchingWallet = false;
  bool _isScanningQr = false;

  bool get _isValid =>
      _kind != null && (!widget.nwcOnly || _kind == WalletInputKind.nwc);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue.trim());
    _kind = classifyWalletInput(_controller.text);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _kindLabel(ndk_l10n.AppLocalizations l10n, WalletInputKind kind) {
    return switch (kind) {
      WalletInputKind.nwc => l10n.nwcWalletTypeTitle,
      WalletInputKind.bolt12 => l10n.bolt12WalletTypeTitle,
      WalletInputKind.lightningAddress => l10n.lightningAddressInputType,
      WalletInputKind.cashuMint => l10n.cashuWalletTypeTitle,
      WalletInputKind.lnBits => l10n.lnbitsWalletOption,
    };
  }

  Future<void> _connectWalletApp() async {
    final connect = widget.connectWalletApp;
    if (connect == null || _isLaunchingWallet) return;
    setState(() => _isLaunchingWallet = true);
    try {
      await connect();
      if (!mounted) return;
      Navigator.of(
        context,
      ).pop(const _ManualWalletInputResult.connectionStarted());
    } finally {
      if (mounted) setState(() => _isLaunchingWallet = false);
    }
  }

  Future<void> _scanQrCode() async {
    if (_isScanningQr) return;
    setState(() => _isScanningQr = true);
    try {
      final value = await _showWalletDialog<String>(
        context: context,
        builder: (_) => const _QrCodeScannerDialog(),
      );
      if (!mounted || value == null) return;
      _controller.text = value;
      _controller.selection = TextSelection.collapsed(offset: value.length);
      setState(() => _kind = classifyWalletInput(value));
    } finally {
      if (mounted) setState(() => _isScanningQr = false);
    }
  }

  Future<void> _pasteInput() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final value = clipboardData?.text?.trim() ?? '';
    _controller.text = value;
    _controller.selection = TextSelection.collapsed(offset: value.length);
    setState(() => _kind = classifyWalletInput(value));
  }

  void _clearInput() {
    _controller.clear();
    setState(() => _kind = null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ndk_l10n.AppLocalizations.of(context)!;
    final kind = _kind;
    final hasInput = _controller.text.trim().isNotEmpty;
    final isNwcInput = kind == WalletInputKind.nwc;

    return AlertDialog(
      title: Text(widget.nwcOnly ? l10n.manualNwcConnection : l10n.walletInput),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              autocorrect: false,
              obscureText: isNwcInput,
              enableSuggestions: !isNwcInput,
              keyboardType: TextInputType.url,
              minLines: isNwcInput ? 1 : 2,
              maxLines: isNwcInput ? 1 : 4,
              onChanged: (value) {
                setState(() => _kind = classifyWalletInput(value));
              },
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: widget.nwcOnly
                    ? l10n.nwcConnectionUriHint
                    : widget.supportedInputDescription,
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: _pasteInput,
                      tooltip: l10n.paste,
                      icon: const Icon(Icons.content_paste_outlined),
                    ),
                    if (widget.nwcOnly &&
                        _WalletQrScannerScope.of(context) != null)
                      IconButton(
                        onPressed: _isScanningQr ? null : _scanQrCode,
                        tooltip: l10n.scanWalletQrCode,
                        icon: _isScanningQr
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.qr_code_scanner),
                      ),
                    if (hasInput)
                      IconButton(
                        onPressed: _clearInput,
                        tooltip: l10n.clearInput,
                        icon: const Icon(Icons.clear),
                      ),
                  ],
                ),
              ),
            ),
            if (widget.nwcOnly && widget.connectWalletApp != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLaunchingWallet ? null : _connectWalletApp,
                  icon: _isLaunchingWallet
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.account_balance_wallet_outlined),
                  label: Text(l10n.oneClickConnect),
                ),
              ),
            ],
            if (hasInput) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    _isValid ? Icons.check_circle : Icons.error_outline,
                    size: 18,
                    color: _isValid
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isValid
                          ? '${l10n.detected}: ${_kindLabel(l10n, kind!)}'
                          : l10n.unsupportedWalletInput,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _isValid
              ? () => Navigator.of(
                  context,
                ).pop(_ManualWalletInputResult.value(_controller.text.trim()))
              : null,
          child: Text(l10n.reviewWallet),
        ),
      ],
    );
  }
}

class _ManualWalletInputResult {
  final String? value;
  final bool connectionStarted;

  const _ManualWalletInputResult.value(this.value) : connectionStarted = false;

  const _ManualWalletInputResult.connectionStarted()
    : value = null,
      connectionStarted = true;
}

class _QrCodeScannerDialog extends StatefulWidget {
  const _QrCodeScannerDialog();

  @override
  State<_QrCodeScannerDialog> createState() => _QrCodeScannerDialogState();
}

class _QrCodeScannerDialogState extends State<_QrCodeScannerDialog> {
  bool _hasScanned = false;
  String? _error;

  void _complete(String? value) {
    final normalized = value?.trim();
    if (!mounted || _hasScanned || normalized == null || normalized.isEmpty) {
      return;
    }
    _hasScanned = true;
    Navigator.of(context).pop(normalized);
  }

  void _onCameraError(Object error) {
    if (!mounted || _error == error.toString()) return;
    setState(() => _error = error.toString());
  }

  @override
  Widget build(BuildContext context) {
    final scannerBuilder = _WalletQrScannerScope.of(context);
    final l10n = ndk_l10n.AppLocalizations.of(context)!;
    return Dialog(
      backgroundColor: Colors.black,
      child: SizedBox(
        width: 400,
        height: 560,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.scanWalletQrCode,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
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
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (scannerBuilder != null)
                    scannerBuilder(context, _complete, _onCameraError)
                  else
                    Center(
                      child: Text(
                        l10n.cameraNotAvailable,
                        style: const TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
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
                  if (_error != null)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        color: Colors.black87,
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
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
}

class _WalletChooserDialog extends StatefulWidget {
  final WalletInputScannerConfiguration configuration;

  const _WalletChooserDialog({required this.configuration});

  @override
  State<_WalletChooserDialog> createState() => _WalletChooserDialogState();
}

class _WalletChooserDialogState extends State<_WalletChooserDialog> {
  WalletInputScannerConfiguration get configuration => widget.configuration;

  @override
  void initState() {
    super.initState();
    if (configuration.openCashuMintChooserInitially) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openCashu(context);
      });
    }
  }

  WalletScannerConnectionOption? get _coinosOption {
    for (final option in configuration.connectionOptions) {
      if (option.id == 'coinos') return option;
    }
    return null;
  }

  WalletScannerConnectionOption? get _installedWalletOption {
    for (final option in configuration.connectionOptions) {
      if (option.kind == WalletScannerConnectionKind.installedWallet) {
        return option;
      }
    }
    return null;
  }

  Future<void> _manualNwc(BuildContext context) async {
    final result = await _showWalletDialog<_ManualWalletInputResult>(
      context: context,
      builder: (_) => _ManualWalletInputDialog(
        initialValue: '',
        supportedInputDescription: configuration.supportedInputDescription,
        nwcOnly: true,
        connectWalletApp: _installedWalletOption?.connect,
      ),
    );
    if (result != null && context.mounted) {
      Navigator.of(context).pop(
        result.connectionStarted
            ? const WalletInputScanResult.connectionStarted()
            : WalletInputScanResult.value(
                result.value,
                manuallyEntered: true,
                origin: WalletInputOrigin.walletChooser,
              ),
      );
    }
  }

  Future<void> _connectCoinos(BuildContext context) async {
    final option = _coinosOption;
    if (option == null) return;
    await option.connect();
    if (context.mounted &&
        configuration.connectionState.value.phase !=
            WalletConnectionPhase.idle) {
      Navigator.of(
        context,
      ).pop(const WalletInputScanResult.connectionStarted());
    }
  }

  Future<void> _openAlby(BuildContext context) async {
    final result = await _showWalletDialog<WalletInputScanResult>(
      context: context,
      builder: (_) => _AlbyChooserDialog(configuration: configuration),
    );
    if (result != null && context.mounted) Navigator.of(context).pop(result);
  }

  Future<void> _openCashu(BuildContext context) async {
    final result = await _showWalletDialog<WalletInputScanResult>(
      context: context,
      builder: (_) => _CashuMintChooserDialog(configuration: configuration),
    );
    if (result != null && context.mounted) Navigator.of(context).pop(result);
  }

  Future<void> _openLnBits(BuildContext context) async {
    final result = await _showWalletDialog<LnBitsConnectionInput>(
      context: context,
      builder: (_) => _LnBitsConnectionDialog(
        validate: configuration.validateLnBitsConnection,
      ),
    );
    if (result != null && context.mounted) {
      Navigator.of(context).pop(WalletInputScanResult.lnBits(result));
    }
  }

  void _returnToScanner(BuildContext context) {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ndk_l10n.AppLocalizations.of(context)!;

    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(l10n.chooseWallet)),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: 148,
          children: [
            if (_WalletQrScannerScope.of(context) != null)
              _WalletGridTile(
                label: l10n.scanWalletQrCode,
                icon: const _BrandIconFrame(
                  backgroundColor: Colors.black,
                  child: Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 42,
                  ),
                ),
                onTap: () => _returnToScanner(context),
              ),
            _WalletGridTile(
              label: l10n.albyWalletOption,
              icon: const _AlbyHubIcon(),
              onTap: () => _openAlby(context),
            ),
            if (_coinosOption != null)
              _WalletGridTile(
                label: l10n.coinosWalletOption,
                icon: const _CoinosIcon(),
                onTap: () => _connectCoinos(context),
              ),
            _WalletGridTile(
              label: l10n.cashuOption,
              icon: const _BrandIconFrame(
                backgroundColor: Color(0xFFFFF3D7),
                child: Image(
                  image: AssetImage(
                    'assets/images/cashu.png',
                    package: 'ndk_flutter',
                  ),
                  width: 44,
                  height: 44,
                ),
              ),
              onTap: () => _openCashu(context),
            ),
            _WalletGridTile(
              label: 'NWC',
              icon: const _NwcIcon(),
              onTap: () => _manualNwc(context),
            ),
            _WalletGridTile(
              label: l10n.lnbitsWalletOption,
              icon: const _LnBitsIcon(),
              onTap: () => _openLnBits(context),
            ),
            for (final option in configuration.connectionOptions)
              if (option.kind == WalletScannerConnectionKind.custom &&
                  option.id != 'alby-cloud' &&
                  option.id != 'coinos')
                _WalletGridTile(
                  label: option.label,
                  icon:
                      option.iconBuilder?.call(context) ??
                      const Icon(Icons.account_balance_wallet_outlined),
                  onTap: () async {
                    await option.connect();
                    if (context.mounted) {
                      Navigator.of(
                        context,
                      ).pop(const WalletInputScanResult.connectionStarted());
                    }
                  },
                ),
          ],
        ),
      ),
    );
  }
}

class _LnBitsConnectionDialog extends StatefulWidget {
  final Future<LnBitsConnectionInput> Function(LnBitsConnectionInput input)?
  validate;

  const _LnBitsConnectionDialog({this.validate});

  @override
  State<_LnBitsConnectionDialog> createState() =>
      _LnBitsConnectionDialogState();
}

class _LnBitsConnectionDialogState extends State<_LnBitsConnectionDialog> {
  final _adminKeyController = TextEditingController();
  final _urlController = TextEditingController(text: 'https://');
  bool _showAdminKey = false;
  bool _readOnly = false;
  bool _isValidating = false;
  String? _error;

  Future<void> _scanInto(TextEditingController controller) async {
    final value = await _showWalletDialog<String>(
      context: context,
      builder: (_) => const _QrCodeScannerDialog(),
    );
    if (!mounted || value == null) return;
    final normalized = value.trim();
    controller.text = normalized;
    controller.selection = TextSelection.collapsed(offset: normalized.length);
    setState(() => _error = null);
  }

  @override
  void dispose() {
    _adminKeyController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final l10n = ndk_l10n.AppLocalizations.of(context)!;
    final adminKey = _adminKeyController.text.trim();
    final url = _urlController.text.trim();
    if (adminKey.isEmpty || url.isEmpty || url == 'https://') {
      setState(() => _error = l10n.lnbitsCredentialsRequired);
      return;
    }
    final input = LnBitsConnectionInput(
      url: url,
      adminKey: adminKey,
      readOnly: _readOnly,
    );
    final validate = widget.validate;
    if (validate == null) {
      Navigator.of(context).pop(input);
      return;
    }
    setState(() {
      _isValidating = true;
      _error = null;
    });
    try {
      final validated = await validate(input);
      if (mounted) Navigator.of(context).pop(validated);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isValidating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ndk_l10n.AppLocalizations.of(context)!;
    return AlertDialog(
      title: Row(
        children: [
          const _LnBitsIcon(),
          const SizedBox(width: 16),
          Expanded(child: Text(l10n.lnbitsWalletOption)),
          IconButton(
            onPressed: _isValidating ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.lnbitsConnectionInstructions),
            const SizedBox(height: 20),
            DropdownButtonFormField<bool>(
              initialValue: _readOnly,
              isExpanded: true,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.lnbitsKeyType,
              ),
              items: [
                DropdownMenuItem(
                  value: false,
                  child: Text(l10n.lnbitsAdminKey),
                ),
                DropdownMenuItem(
                  value: true,
                  child: Text(l10n.lnbitsInvoiceReadKey),
                ),
              ],
              onChanged: _isValidating
                  ? null
                  : (value) => setState(() => _readOnly = value ?? false),
            ),
            if (_readOnly) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(l10n.lnbitsReadOnlyDescription)),
                ],
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _adminKeyController,
              enabled: !_isValidating,
              obscureText: !_showAdminKey,
              enableSuggestions: false,
              autocorrect: false,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: _readOnly
                    ? l10n.lnbitsInvoiceReadKey
                    : l10n.lnbitsAdminKey,
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: _isValidating
                          ? null
                          : () => _scanInto(_adminKeyController),
                      tooltip: l10n.scanWalletQrCode,
                      icon: const Icon(Icons.qr_code_scanner),
                    ),
                    IconButton(
                      onPressed: () => setState(() {
                        _showAdminKey = !_showAdminKey;
                      }),
                      icon: Icon(
                        _showAdminKey ? Icons.visibility_off : Icons.visibility,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _urlController,
              enabled: !_isValidating,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.lnbitsUrl,
                suffixIcon: IconButton(
                  onPressed: _isValidating
                      ? null
                      : () => _scanInto(_urlController),
                  tooltip: l10n.scanWalletQrCode,
                  icon: const Icon(Icons.qr_code_scanner),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isValidating ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _isValidating ? null : _continue,
          child: _isValidating
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.reviewWallet),
        ),
      ],
    );
  }
}

class _CashuMintChooserDialog extends StatefulWidget {
  final WalletInputScannerConfiguration configuration;

  const _CashuMintChooserDialog({required this.configuration});

  @override
  State<_CashuMintChooserDialog> createState() =>
      _CashuMintChooserDialogState();
}

class _CashuMintChooserDialogState extends State<_CashuMintChooserDialog> {
  late Future<List<CashuMintSuggestion>> _suggestions;

  @override
  void initState() {
    super.initState();
    _suggestions = widget.configuration.discoverCashuMints();
  }

  void _retry() {
    setState(() {
      _suggestions = widget.configuration.discoverCashuMints();
    });
  }

  Future<void> _enterMintUrl() async {
    final l10n = ndk_l10n.AppLocalizations.of(context)!;
    final result = await _showWalletDialog<_ManualWalletInputResult>(
      context: context,
      builder: (_) => _ManualWalletInputDialog(
        initialValue: 'https://',
        supportedInputDescription: l10n.enterMintUrl,
        nwcOnly: false,
      ),
    );
    final value = result?.value?.trim();
    if (!mounted || value == null) return;
    if (classifyWalletInput(value) != WalletInputKind.cashuMint) return;
    Navigator.of(context).pop(
      WalletInputScanResult.value(
        value,
        manuallyEntered: true,
        origin: WalletInputOrigin.cashuMintChooser,
      ),
    );
  }

  void _selectMint(CashuMintSuggestion mint) {
    Navigator.of(context).pop(
      WalletInputScanResult.value(
        mint.url,
        origin: WalletInputOrigin.cashuMintChooser,
        cashuMintSuggestion: mint,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ndk_l10n.AppLocalizations.of(context)!;
    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(l10n.chooseCashuMint)),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      content: SizedBox(
        width: 460,
        height: 480,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.cashuMintRatingsNotice,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<CashuMintSuggestion>>(
                future: _suggestions,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.cashuMintDiscoveryFailed,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _retry,
                            icon: const Icon(Icons.refresh),
                            label: Text(l10n.retry),
                          ),
                        ],
                      ),
                    );
                  }
                  final suggestions = snapshot.data ?? const [];
                  if (suggestions.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.noCashuMintSuggestions,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _retry,
                            icon: const Icon(Icons.refresh),
                            label: Text(l10n.retry),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    scrollCacheExtent: const ScrollCacheExtent.pixels(0),
                    itemCount: suggestions.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final mint = suggestions[index];
                      return _CashuMintListTile(
                        mint: mint,
                        enrich: widget.configuration.enrichCashuMint,
                        onSelected: _selectMint,
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _enterMintUrl,
              icon: const Icon(Icons.edit_outlined),
              label: Text(l10n.enterMintUrlManually),
            ),
          ],
        ),
      ),
    );
  }
}

class _CashuMintListTile extends StatefulWidget {
  final CashuMintSuggestion mint;
  final Future<CashuMintSuggestion> Function(CashuMintSuggestion mint) enrich;
  final ValueChanged<CashuMintSuggestion> onSelected;

  const _CashuMintListTile({
    required this.mint,
    required this.enrich,
    required this.onSelected,
  });

  @override
  State<_CashuMintListTile> createState() => _CashuMintListTileState();
}

class _CashuMintListTileState extends State<_CashuMintListTile> {
  late final Future<CashuMintSuggestion> _enriched;
  bool _selecting = false;

  @override
  void initState() {
    super.initState();
    _enriched = widget.enrich(widget.mint);
  }

  Future<void> _select() async {
    if (_selecting) return;
    setState(() => _selecting = true);
    CashuMintSuggestion mint;
    try {
      mint = await _enriched;
    } catch (_) {
      mint = widget.mint;
    }
    if (mounted) widget.onSelected(mint);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ndk_l10n.AppLocalizations.of(context)!;
    return FutureBuilder<CashuMintSuggestion>(
      future: _enriched,
      initialData: widget.mint,
      builder: (context, snapshot) {
        final mint = snapshot.data ?? widget.mint;
        final rating = mint.averageRating;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 4,
          ),
          leading: _CashuMintIcon(mint: mint),
          title: Text(mint.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(mint.url, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(
                rating == null
                    ? l10n.noRatingsYet
                    : l10n.cashuMintRating(
                        rating.toStringAsFixed(1),
                        mint.reviewsCount,
                      ),
              ),
            ],
          ),
          trailing: _selecting
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.chevron_right),
          onTap: _selecting ? null : _select,
        );
      },
    );
  }
}

class _AlbyChooserDialog extends StatelessWidget {
  final WalletInputScannerConfiguration configuration;

  const _AlbyChooserDialog({required this.configuration});

  WalletScannerConnectionOption? get _albyGoOption {
    for (final option in configuration.connectionOptions) {
      if (option.kind == WalletScannerConnectionKind.albyGo) return option;
    }
    return null;
  }

  WalletScannerConnectionOption? get _albyCloudOption {
    for (final option in configuration.connectionOptions) {
      if (option.id == 'alby-cloud') return option;
    }
    return null;
  }

  Future<void> _openCloud(BuildContext context) async {
    final option = _albyCloudOption;
    if (option == null) return;
    await option.connect();
    if (context.mounted) {
      Navigator.of(
        context,
      ).pop(const WalletInputScanResult.connectionStarted());
    }
  }

  Future<void> _connectAlbyGo(BuildContext context) async {
    final option = _albyGoOption;
    if (option == null) return;
    await option.connect();
    if (context.mounted &&
        configuration.connectionState.value.phase !=
            WalletConnectionPhase.idle) {
      Navigator.of(
        context,
      ).pop(const WalletInputScanResult.connectionStarted());
    }
  }

  Future<void> _manualNwc(BuildContext context) async {
    final result = await _showWalletDialog<_ManualWalletInputResult>(
      context: context,
      builder: (_) => _ManualWalletInputDialog(
        initialValue: '',
        supportedInputDescription: configuration.supportedInputDescription,
        nwcOnly: true,
      ),
    );
    if (result?.value != null && context.mounted) {
      Navigator.of(context).pop(
        WalletInputScanResult.value(
          result!.value,
          manuallyEntered: true,
          origin: WalletInputOrigin.walletChooser,
          providerId: 'alby',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ndk_l10n.AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.albyWalletOption),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const _AlbyHubIcon(),
              title: Text(l10n.albyCloudOption),
              subtitle: const Text('my.albyhub.com'),
              trailing: const Icon(Icons.open_in_new),
              enabled: _albyCloudOption != null,
              onTap: _albyCloudOption == null
                  ? null
                  : () => _openCloud(context),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const _AlbyGoIcon(),
              title: Text(l10n.albyGoOption),
              trailing: const Icon(Icons.chevron_right),
              enabled: _albyGoOption != null,
              onTap: _albyGoOption == null
                  ? null
                  : () => _connectAlbyGo(context),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const _NwcIcon(),
              title: Text(l10n.manualNwcConnection),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _manualNwc(context),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}

class _AlbyHubIcon extends StatelessWidget {
  const _AlbyHubIcon();

  @override
  Widget build(BuildContext context) {
    return _BrandIconFrame(
      backgroundColor: Colors.white,
      child: SvgPicture.asset(
        'assets/images/albyhub.svg',
        package: 'ndk_flutter',
        width: 40,
        height: 40,
      ),
    );
  }
}

class _AlbyGoIcon extends StatelessWidget {
  const _AlbyGoIcon();

  @override
  Widget build(BuildContext context) {
    return _BrandIconFrame(
      backgroundColor: Colors.white,
      child: Image.asset(
        'assets/images/albygo.png',
        package: 'ndk_flutter',
        width: 40,
        height: 40,
      ),
    );
  }
}

class _CashuMintIcon extends StatelessWidget {
  final CashuMintSuggestion mint;

  const _CashuMintIcon({required this.mint});

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(
      Icons.toll_outlined,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    final iconUrl = mint.iconUrl;

    return CircleAvatar(
      radius: 24,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: ClipOval(
        child: iconUrl == null
            ? fallback
            : Image.network(
                iconUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
              ),
      ),
    );
  }
}

class _CoinosIcon extends StatelessWidget {
  const _CoinosIcon();

  @override
  Widget build(BuildContext context) {
    return _BrandIconFrame(
      backgroundColor: Colors.white,
      child: SvgPicture.asset(
        'assets/images/coinos.svg',
        package: 'ndk_flutter',
        width: 48,
        height: 48,
      ),
    );
  }
}

class _NwcIcon extends StatelessWidget {
  const _NwcIcon();

  @override
  Widget build(BuildContext context) {
    return _BrandIconFrame(
      backgroundColor: Colors.white,
      child: Image.asset(
        'assets/images/nwc.png',
        package: 'ndk_flutter',
        width: 48,
        height: 48,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _LnBitsIcon extends StatelessWidget {
  const _LnBitsIcon();

  @override
  Widget build(BuildContext context) {
    return _BrandIconFrame(
      backgroundColor: const Color(0xFF673AB7),
      child: SvgPicture.asset(
        'assets/images/lnbits.svg',
        package: 'ndk_flutter',
        width: 64,
        height: 64,
      ),
    );
  }
}

class _BrandIconFrame extends StatelessWidget {
  final Color backgroundColor;
  final Widget child;

  const _BrandIconFrame({required this.backgroundColor, required this.child});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: dark
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.25),
            offset: const Offset(0, 10),
            blurRadius: 15,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ColoredBox(
          color: backgroundColor,
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _WalletGridTile extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback onTap;

  const _WalletGridTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
          child: Column(
            children: [
              icon,
              const SizedBox(height: 8),
              Expanded(
                child: Center(
                  child: Tooltip(
                    message: label,
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
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
