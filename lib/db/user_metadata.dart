import 'package:dart_ndk/nips/nip01/helpers.dart';
import 'package:dart_ndk/nips/nip01/metadata.dart';
import 'package:isar/isar.dart';

part 'user_metadata.g.dart';

@collection
class UserMetadata extends Metadata {
  String get id => pubKey!;

  UserMetadata({
    super.pubKey = "",
    super.name,
    super.displayName,
    super.picture,
    super.banner,
    super.website,
    super.about,
    super.nip05,
    super.lud16,
    super.lud06,
    super.updatedAt,
  });

  String getName() {
    if (displayName != null && Helpers.isNotBlank(displayName)) {
      return displayName!;
    }
    if (name != null && Helpers.isNotBlank(name)) {
      return name!;
    }
    return pubKey!;
  }

  bool matchesSearch(String str) {
    str = str.trim().toLowerCase();
    String d = displayName != null ? displayName!.toLowerCase()! : "";
    String n = name != null ? name!.toLowerCase()! : "";
    String str2 = " $str";
    return d.startsWith(str) ||
        d.contains(str2) ||
        n.startsWith(str) ||
        n.contains(str2);
  }

  static UserMetadata fromMetadata(Metadata metadata) {
    return UserMetadata(
      pubKey: metadata.pubKey,
      name: metadata.name,
      displayName: metadata.displayName,
      picture: metadata.picture,
      banner: metadata.banner,
      website: metadata.website,
      about: metadata.about,
      nip05: metadata.nip05,
      lud16: metadata.lud16,
      lud06: metadata.lud06,
      updatedAt: metadata.updatedAt,
    );
  }
}
