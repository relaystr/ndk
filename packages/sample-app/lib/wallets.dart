import 'package:flutter/material.dart';
import 'package:ndk_demo/l10n/app_localizations_context.dart';
import 'package:ndk_flutter/ndk_flutter.dart';

import 'main.dart';
import 'nwc_qr_scanner.dart';

const _sampleAppName = 'NDK Demo';
const _sampleCallback = 'ndk://nwc';
const _coinosRelay = 'wss://relay.coinos.io';
const _coinosWalletServicePubkey =
    'ba80990666ef0b6f4ba5059347beb13242921e54669e680064ca755256a1e3a6';

class WalletsPage extends StatefulWidget {
  final String? initialUrl;

  const WalletsPage({super.key, this.initialUrl});

  @override
  State<WalletsPage> createState() => WalletsPageState();
}

class WalletsPageState extends State<WalletsPage> with WidgetsBindingObserver {
  final GlobalKey<NWalletsState> _walletsKey = GlobalKey<NWalletsState>();
  AppLifecycleState? _appLifecycleState;
  String? _deferredProtocolUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    activeWalletProtocolHandler = onProtocolUrlReceived;
    _appLifecycleState = WidgetsBinding.instance.lifecycleState;
    if (widget.initialUrl != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onProtocolUrlReceived(widget.initialUrl!);
      });
    }
  }

  @override
  void dispose() {
    if (activeWalletProtocolHandler == onProtocolUrlReceived) {
      activeWalletProtocolHandler = null;
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appLifecycleState = state;
    if (!mounted || state != AppLifecycleState.resumed) {
      return;
    }

    final deferredProtocolUrl = _deferredProtocolUrl;
    _deferredProtocolUrl = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (deferredProtocolUrl != null) {
        _walletsKey.currentState?.onProtocolUrlReceived(deferredProtocolUrl);
      } else {
        _walletsKey.currentState?.resumePendingWalletAuth();
      }
    });
  }

  Future<void> onProtocolUrlReceived(String url) async {
    if (_appLifecycleState != AppLifecycleState.resumed) {
      _deferredProtocolUrl = url;
      return;
    }

    await _walletsKey.currentState?.onProtocolUrlReceived(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.tabWallets)),
      body: NWallets(
        key: _walletsKey,
        ndkFlutter: ndkFlutter,
        walletInputScanner: scanWalletInput,
        nwcConnectionOptions: [
          NwcConnectionOption(
            id: 'alby-cloud',
            label: 'Alby Cloud',
            connect: (context, ndkFlutter, coordinator) {
              return coordinator.connectWebWalletAuth(
                context,
                authorizationEndpoint: Uri.parse(
                  'https://my.albyhub.com/apps/new',
                ),
                appName: _sampleAppName,
                discoveryRelay: kDefaultAlbyGoConnectConfig.discoveryRelay,
                callback: _sampleCallback,
                walletName: 'Alby Cloud',
                additionalQueryParameters: const {
                  'return_to': _sampleCallback,
                },
              );
            },
          ),
          NwcConnectionOption(
            id: 'coinos',
            label: 'Coinos',
            connect: (context, ndkFlutter, coordinator) {
              return coordinator.connectWebWalletAuth(
                context,
                authorizationEndpoint: Uri.parse('https://coinos.io/apps/new'),
                appName: _sampleAppName,
                discoveryRelay: _coinosRelay,
                callback: _sampleCallback,
                walletName: 'Coinos',
                walletServicePubkey: _coinosWalletServicePubkey,
              );
            },
          ),
        ],
      ),
    );
  }
}
