import 'dart:async';
import '../../rust_bridge/frb_generated.dart';

/// Singleton class to manage RustLib initialization
class RustLibInitializer {
  static final RustLibInitializer _instance = RustLibInitializer._internal();
  final Completer<bool> _isInitialized = Completer<bool>();
  bool _initCalled = false;

  factory RustLibInitializer() {
    return _instance;
  }

  RustLibInitializer._internal();

  /// Ensures RustLib is initialized. Safe to call multiple times.
  Future<void> ensureInitialized() async {
    if (!_initCalled) {
      _initCalled = true;
      await RustLib.init();
      _isInitialized.complete(true);
    } else {
      await _isInitialized.future;
    }
  }
}
