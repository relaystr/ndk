import 'package:flutter/material.dart';
import 'package:ndk_flutter/ndk_flutter.dart';

import 'main.dart';

class WalletsPage extends StatefulWidget {
  const WalletsPage({super.key});

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
      body: NWallets(key: _walletsKey, ndkFlutter: ndkFlutter),
    );
  }
}
