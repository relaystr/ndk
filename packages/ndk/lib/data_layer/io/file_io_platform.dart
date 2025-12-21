/// Exports the correct FileIO implementation based on platform
export 'file_io_stub.dart'
    if (dart.library.io) 'file_io_native.dart'
    if (dart.library.js_interop) 'file_io_web.dart';
