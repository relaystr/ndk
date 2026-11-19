class EventKindClassification {
  // metadata (0), contact list (3) and channel metadata (41)
  static const _singletonReplaceableKinds = {0, 3, 41};

  static bool isEphemeralKind(int kind) => kind >= 20000 && kind <= 29999;

  static bool isReplaceableKind(int kind) {
    if (isSingletonReplaceableKind(kind)) {
      return true;
    }

    return isRegularReplaceableKind(kind) || isAddressableKind(kind);
  }

  /// Replaceable kinds outside the 10000-19999 range, addressed with an empty
  /// d tag.
  static bool isSingletonReplaceableKind(int kind) =>
      _singletonReplaceableKinds.contains(kind);

  static bool isRegularReplaceableKind(int kind) {
    return kind >= 10000 && kind <= 19999;
  }

  static bool isAddressableKind(int kind) {
    return isParameterizedReplaceableKind(kind);
  }

  static bool isParameterizedReplaceableKind(int kind) {
    return kind >= 30000 && kind <= 39999;
  }
}
