import 'dart:convert';

import '../../shared/nips/nip01/helpers.dart';
import 'nip_01_event.dart';

/// basic nostr metadata
class Metadata {
  static const int kKind = 0;

  /// public key
  late String pubKey;

  /// content JSON to preserve custom fields
  Map<String, dynamic> content = {};

  /// name
  String? get name => content['name'] as String?;
  set name(String? value) => content['name'] = value;

  /// displayName
  String? get displayName => content['display_name'] as String?;
  set displayName(String? value) => content['display_name'] = value;

  /// picture
  String? get picture => content['picture'] as String?;
  set picture(String? value) => content['picture'] = value;

  /// banner
  String? get banner => content['banner'] as String?;
  set banner(String? value) => content['banner'] = value;

  /// website
  String? get website => content['website'] as String?;
  set website(String? value) => content['website'] = value;

  /// about
  String? get about => content['about'] as String?;
  set about(String? value) => content['about'] = value;

  /// nip05
  String? get nip05 => content['nip05'] as String?;
  set nip05(String? value) => content['nip05'] = value;

  /// lud16
  String? get lud16 => content['lud16'] as String?;
  set lud16(String? value) => content['lud16'] = value;

  /// lud06
  String? get lud06 => content['lud06'] as String?;
  set lud06(String? value) => content['lud06'] = value;

  /// updated at
  int? updatedAt;

  /// refreshed timestamp
  int? refreshedTimestamp;

  List<String> sources = [];

  /// event tags (e.g., NIP-39 identity tags)
  List<List<String>> tags = [];

  /// basic metadata nostr
  Metadata({
    this.pubKey = "",
    String? name,
    String? displayName,
    String? picture,
    String? banner,
    String? website,
    String? about,
    String? nip05,
    String? lud16,
    String? lud06,
    this.updatedAt,
    this.refreshedTimestamp,
    List<List<String>>? tags,
    Map<String, dynamic>? content,
  })  : tags = tags ?? [],
        content = content ?? {} {
    // Initialize content with provided known fields
    if (name != null) this.name = name;
    if (displayName != null) this.displayName = displayName;
    if (picture != null) this.picture = picture;
    if (banner != null) this.banner = banner;
    if (website != null) this.website = website;
    if (about != null) this.about = about;
    if (nip05 != null) this.nip05 = nip05;
    if (lud16 != null) this.lud16 = lud16;
    if (lud06 != null) this.lud06 = lud06;
  }

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
      metadata.content = json;
    }
    metadata.pubKey = event.pubKey;
    metadata.updatedAt = event.createdAt;
    metadata.sources = event.sources;
    metadata.tags = event.tags;
    return metadata;
  }

  /// convert to nip01 event
  Nip01Event toEvent() {
    // Merge with original content to preserve custom fields
    final Map<String, dynamic> content =
        Map<String, dynamic>.from(this.content);
    // Update with current values
    content.addAll(toJson());

    return Nip01Event(
        pubKey: pubKey,
        content: jsonEncode(content),
        kind: kKind,
        tags: tags,
        createdAt: updatedAt ?? 0);
  }

  /// Set a custom field in the content
  /// Works for both known fields (name, display_name, etc.) and custom fields
  void setCustomField(String key, dynamic value) {
    content[key] = value;
  }

  /// Get a custom field from the content
  dynamic getCustomField(String key) {
    return content[key];
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
    List<List<String>>? tags,
    Map<String, dynamic>? content,
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
      tags: tags ?? List.from(this.tags),
      content: content ?? this.content,
    );

    metadata.sources = sources ?? List.from(this.sources);
    return metadata;
  }
}
