import 'dart:convert';

import '../../shared/nips/nip01/helpers.dart';
import '../usecases/nip_01_event_service/nip_01_event_service.dart';
import 'nip_01_event.dart';

/// basic nostr metadata
class Metadata {
  static const int kKind = 0;

  /// public key
  late String pubKey;

  /// name
  String? name;

  /// displayName
  String? displayName;

  /// picture
  String? picture;

  /// banner
  String? banner;

  /// website
  String? website;

  /// about
  String? about;

  /// nip05
  String? nip05;

  /// lud16
  String? lud16;

  /// lud06
  String? lud06;

  /// updated at
  int? updatedAt;

  /// refreshed timestamp
  int? refreshedTimestamp;

  List<String> sources = [];

  /// basic metadata nostr
  Metadata(
      {this.pubKey = "",
      this.name,
      this.displayName,
      this.picture,
      this.banner,
      this.website,
      this.about,
      this.nip05,
      this.lud16,
      this.lud06,
      this.updatedAt,
      this.refreshedTimestamp});

  /// convert from json
  Metadata.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    displayName = json['display_name'];
    picture = json['picture'];
    banner = json['banner'];
    website = json['website'];
    about = json['about'];
    try {
      nip05 = json['nip05'];
    } catch (e) {
      // sometimes people put maps in here
    }
    lud16 = json['lud16'];
    lud06 = json['lud06'];
  }

  /// clean nip05
  String? get cleanNip05 {
    if (nip05 != null) {
      if (nip05!.startsWith("_@")) {
        return nip05!.trim().toLowerCase().replaceAll("_@", "@");
      }
      return nip05!.trim().toLowerCase();
    }
    return null;
  }

  /// convert to json (full all fields)
  Map<String, dynamic> toFullJson() {
    var data = toJson();
    data['pub_key'] = pubKey;
    return data;
  }

  /// convert from json (except pub_key)
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['display_name'] = displayName;
    data['picture'] = picture;
    data['banner'] = banner;
    data['website'] = website;
    data['about'] = about;
    data['nip05'] = nip05;
    data['lud16'] = lud16;
    data['lud06'] = lud06;
    return data;
  }

  /// convert from nip01 event
  static Metadata fromEvent(Nip01Event event) {
    Metadata metadata = Metadata();
    if (Helpers.isNotBlank(event.content)) {
      Map<String, dynamic> json = jsonDecode(event.content);
      metadata = Metadata.fromJson(json);
    }
    metadata.pubKey = event.pubKey;
    metadata.updatedAt = event.createdAt;
    metadata.sources = event.sources;
    return metadata;
  }

  /// convert to nip01 event
  Nip01Event toEvent() {
    return Nip01EventService.createEventCalculateId(
        pubKey: pubKey,
        content: jsonEncode(toJson()),
        kind: kKind,
        tags: [],
        createdAt: updatedAt ?? 0);
  }

  /// return display name if set, otherwise name if set, otherwise pubKey
  String getName() {
    if (displayName != null && Helpers.isNotBlank(displayName)) {
      return displayName!;
    }
    if (name != null && Helpers.isNotBlank(name)) {
      return name!;
    }
    return pubKey;
  }

  /// does it match while searching for given string
  bool matchesSearch(String str) {
    str = str.trim().toLowerCase();
    String d = displayName != null ? displayName!.toLowerCase() : "";
    String n = name != null ? name!.toLowerCase() : "";
    String str2 = " $str";
    return d.startsWith(str) ||
        d.contains(str2) ||
        n.startsWith(str) ||
        n.contains(str2);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Metadata &&
          runtimeType == other.runtimeType &&
          pubKey == other.pubKey;

  @override
  int get hashCode => pubKey.hashCode;

  Metadata copyWith({
    String? pubKey,
    String? name,
    String? displayName,
    String? picture,
    String? banner,
    String? website,
    String? about,
    String? nip05,
    String? lud16,
    String? lud06,
    int? updatedAt,
    int? refreshedTimestamp,
    List<String>? sources,
  }) {
    Metadata metadata = Metadata(
      pubKey: pubKey ?? this.pubKey,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      picture: picture ?? this.picture,
      banner: banner ?? this.banner,
      website: website ?? this.website,
      about: about ?? this.about,
      nip05: nip05 ?? this.nip05,
      lud16: lud16 ?? this.lud16,
      lud06: lud06 ?? this.lud06,
      updatedAt: updatedAt ?? this.updatedAt,
      refreshedTimestamp: refreshedTimestamp ?? this.refreshedTimestamp,
    );

    metadata.sources = sources ?? List.from(this.sources);
    return metadata;
  }
}
