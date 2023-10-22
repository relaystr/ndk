import 'package:isar/isar.dart';

enum ReadWriteMarker {
  readOnly("r"),
  writeOnly("w"),
  readWrite("rw");

  const ReadWriteMarker(this.asText);

  @enumValue
  final String asText;

  static ReadWriteMarker from({required bool read, required bool write}) {
    if (read) {
      if (write) {
        return ReadWriteMarker.readWrite;
      }
      return ReadWriteMarker.readOnly;
    }
    if (write) {
      return ReadWriteMarker.writeOnly;
    }
    throw Exception("illegal read & write false values for this marker");
  }

  bool get isRead =>
      this == ReadWriteMarker.readOnly || this == ReadWriteMarker.readWrite;

  bool get isWrite =>
      this == ReadWriteMarker.writeOnly || this == ReadWriteMarker.readWrite;

  // Map<String,dynamic> toJson() {
  //   return {"name":asText};
  // }
  //
  // ReadWriteMarker fromJson(Map<String,dynamic> map) {
  //   switch (map["name"]) {
  //     case "r":
  //       return ReadWriteMarker.readOnly;
  //     case "w":
  //       return ReadWriteMarker.writeOnly;
  //   }
  //   return ReadWriteMarker.readWrite;
  // }
}
