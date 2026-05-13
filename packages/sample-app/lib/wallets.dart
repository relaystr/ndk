import 'package:flutter/material.dart';
import 'package:ndk_demo/l10n/app_localizations_context.dart';
import 'package:ndk_flutter/ndk_flutter.dart';

import 'main.dart';

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
    _appLifecycleState = WidgetsBinding.instance.lifecycleState;
    if (widget.initialUrl != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onProtocolUrlReceived(widget.initialUrl!);
      });
    }
  }

  @override
  void dispose() {
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
    if (deferredProtocolUrl == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _walletsKey.currentState?.onProtocolUrlReceived(deferredProtocolUrl);
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
      body: NWallets(key: _walletsKey, ndkFlutter: ndkFlutter),
    );
  }
}
