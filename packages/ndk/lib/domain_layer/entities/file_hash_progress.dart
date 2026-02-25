class FileHashProgress {
  final int processedBytes;
  final int totalBytes;
  final bool isComplete;
  final String? hash;

  FileHashProgress({
    required this.processedBytes,
    required this.totalBytes,
    this.isComplete = false,
    this.hash,
  });

  double get progress => totalBytes > 0 ? processedBytes / totalBytes : 0;
  double get percentage => progress * 100;
}
