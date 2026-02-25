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

  /// Private cached fields for known properties
  String? _name;
  String? _displayName;
  String? _picture;
  String? _banner;
  String? _website;
  String? _about;
  String? _nip05;
  String? _lud16;
  String? _lud06;

  /// name
  String? get name => _name;
  set name(String? value) {
    _name = value;
    content['name'] = value;
  }

  /// displayName
  String? get displayName => _displayName;
  set displayName(String? value) {
    _displayName = value;
    content['display_name'] = value;
  }

  /// picture
  String? get picture => _picture;
  set picture(String? value) {
    _picture = value;
    content['picture'] = value;
  }

  /// banner
  String? get banner => _banner;
  set banner(String? value) {
    _banner = value;
    content['banner'] = value;
  }

  /// website
  String? get website => _website;
  set website(String? value) {
    _website = value;
    content['website'] = value;
  }

  /// about
  String? get about => _about;
  set about(String? value) {
    _about = value;
    content['about'] = value;
  }

  /// nip05
  String? get nip05 => _nip05;
  set nip05(String? value) {
    _nip05 = value;
    content['nip05'] = value;
  }

  /// lud16
  String? get lud16 => _lud16;
  set lud16(String? value) {
    _lud16 = value;
    content['lud16'] = value;
  }

  /// lud06
  String? get lud06 => _lud06;
  set lud06(String? value) {
    _lud06 = value;
    content['lud06'] = value;
  }

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
    _name = json['name'];
    _displayName = json['display_name'];
    _picture = json['picture'];
    _banner = json['banner'];
    _website = json['website'];
    _about = json['about'];
    try {
      _nip05 = json['nip05'];
    } catch (e) {
      // sometimes people put maps in here
    }
    _lud16 = json['lud16'];
    _lud06 = json['lud06'];
    
    // Also populate content map for consistency
    if (_name != null) content['name'] = _name;
    if (_displayName != null) content['display_name'] = _displayName;
    if (_picture != null) content['picture'] = _picture;
    if (_banner != null) content['banner'] = _banner;
    if (_website != null) content['website'] = _website;
    if (_about != null) content['about'] = _about;
    if (_nip05 != null) content['nip05'] = _nip05;
    if (_lud16 != null) content['lud16'] = _lud16;
    if (_lud06 != null) content['lud06'] = _lud06;
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
      // Store the full content map for custom fields
      metadata.content = json;
      // Ensure cached fields are populated from content
      metadata._name = json['name'];
      metadata._displayName = json['display_name'];
      metadata._picture = json['picture'];
      metadata._banner = json['banner'];
      metadata._website = json['website'];
      metadata._about = json['about'];
      try {
        metadata._nip05 = json['nip05'];
      } catch (e) {
        // sometimes people put maps in here
      }
      metadata._lud16 = json['lud16'];
      metadata._lud06 = json['lud06'];
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
    
    // Update cached fields if this is a known property
    switch (key) {
      case 'name':
        _name = value as String?;
        break;
      case 'display_name':
        _displayName = value as String?;
        break;
      case 'picture':
        _picture = value as String?;
        break;
      case 'banner':
        _banner = value as String?;
        break;
      case 'website':
        _website = value as String?;
        break;
      case 'about':
        _about = value as String?;
        break;
      case 'nip05':
        _nip05 = value as String?;
        break;
      case 'lud16':
        _lud16 = value as String?;
        break;
      case 'lud06':
        _lud06 = value as String?;
        break;
    }
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
