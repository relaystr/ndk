enum ReadWriteMarker {
  readOnly,
  writeOnly,
  readWrite;

  bool get isRead =>
      this == ReadWriteMarker.readOnly || this == ReadWriteMarker.readWrite;

  bool get isWrite =>
      this == ReadWriteMarker.writeOnly || this == ReadWriteMarker.readWrite;
}
