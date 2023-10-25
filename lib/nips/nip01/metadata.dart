import 'dart:convert';

import 'package:dart_ndk/nips/nip01/event.dart';
import 'package:dart_ndk/nips/nip01/helpers.dart';

class Metadata {

  static const int kind = 0;

  late String pubKey;
  String? name;
  String? displayName;
  String? picture;
  String? banner;
  String? website;
  String? about;
  String? nip05;
  String? lud16;
  String? lud06;
  int? updatedAt;

  Metadata({
    this.pubKey = "",
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
  });

  Metadata.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    displayName = json['display_name'];
    picture = json['picture'];
    banner = json['banner'];
    website = json['website'];
    about = json['about'];
    nip05 = json['nip05'];
    lud16 = json['lud16'];
    lud06 = json['lud06'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toFullJson() {
    var data = toJson();
    data['pub_key'] = pubKey;
    return data;
  }

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
    data['updated_at'] = updatedAt;
    return data;
  }

  static Metadata fromEvent(Nip01Event event) {
    Metadata metadata = Metadata();
    if (Helpers.isNotBlank(event.content)) {
      Map<String,dynamic> json = jsonDecode(event.content);
      if (json!=null) {
        metadata = Metadata.fromJson(json);
      }
    }
    metadata.pubKey = event.pubKey;
    metadata.updatedAt = event.createdAt;
    return metadata;
  }
}
