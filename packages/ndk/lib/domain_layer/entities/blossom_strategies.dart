enum UploadStrategy {
  /// Upload to first server, then mirror to others
  mirrorAfterSuccess,

  /// Upload to all servers simultaneously
  allSimultaneous,

  /// Upload to first successful server only
  firstSuccess
}
