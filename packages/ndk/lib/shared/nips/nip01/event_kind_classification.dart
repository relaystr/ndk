import '../../../domain_layer/entities/contact_list.dart';
import '../../../domain_layer/entities/metadata.dart';
import '../nip28/channel_metadata.dart';

class EventKindClassification {
  static bool isEphemeralKind(int kind) => kind >= 20000 && kind <= 29999;

  static bool isReplaceableKind(int kind) {
    if (kind == Metadata.kKind ||
        kind == ContactList.kKind ||
        kind == ChannelMetadata.kKind) {
      return true;
    }

    return isRegularReplaceableKind(kind) || isAddressableKind(kind);
  }

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
