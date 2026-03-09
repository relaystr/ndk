import 'blossom_blobs.dart';

enum UploadPhase { hashing, uploading, mirroring }

/// Progress information for blob uploads
class BlobUploadProgress {
  final String currentServer;
  final int sentBytes;
  final int totalBytes;
  final List<BlobUploadResult> completedUploads;
  final bool isComplete;

  final UploadPhase phase; // hashing | uploading | mirroring
  final double progressPhase; // 0.0 - 1.0 for current phase
  final double percentagePhase; // 0.0 - 100.0 for current phase

  // For mirroring phase
  final int mirrorsTotal;
  final int mirrorsCompleted;

  BlobUploadProgress({
    required this.currentServer,
    required this.sentBytes,
    required this.totalBytes,
    required this.completedUploads,
    this.phase = UploadPhase.uploading,
    double? progressPhase,
    int? mirrorsTotal,
    int? mirrorsCompleted,
    this.isComplete = false,
  })  : progressPhase =
            ((progressPhase ?? (totalBytes > 0 ? sentBytes / totalBytes : 0))
                    .clamp(0.0, 1.0))
                .toDouble(),
        percentagePhase =
            ((progressPhase ?? (totalBytes > 0 ? sentBytes / totalBytes : 0))
                        .clamp(0.0, 1.0))
                    .toDouble() *
                100,
        mirrorsTotal = mirrorsTotal ?? 0,
        mirrorsCompleted = mirrorsCompleted ?? 0;

  double get uploadProgress => totalBytes > 0 ? sentBytes / totalBytes : 0;

  /// Overall progress mapped across fixed phases:
  /// hashing: 0-33%, uploading: 33-66%, mirroring: 66-100%
  double get progress {
    switch (phase) {
      case UploadPhase.hashing:
        return progressPhase * 0.33;
      case UploadPhase.uploading:
        return 0.33 + (progressPhase * 0.33);
      case UploadPhase.mirroring:
        return 0.66 + (progressPhase * 0.34);
    }
  }

  double get percentage => progress * 100;
}
