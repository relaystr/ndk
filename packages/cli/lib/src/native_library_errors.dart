bool isNativeLibraryLoadError(ArgumentError error) {
  final message = error.toString().toLowerCase();
  return message.contains('dynamic library') ||
      message.contains('failed to lookup symbol') ||
      message.contains("couldn't resolve native function") ||
      message.contains('no available native assets');
}
