import 'dart:convert';

import 'package:objectbox/objectbox.dart';
import 'package:ndk/entities.dart' as ndk_entities;

@Entity()
class DbCashuMintInfo {
  @Id()
  int dbId = 0;

  @Property()
  String? name;

  @Property()
  String? version;

  @Property()
  String? description;

  @Property()
  String? descriptionLong;

  @Property()
  String contactJson;

  @Property()
  String? motd;

  @Property()
  String? iconUrl;

  @Property()
  List<String> urls;

  @Property()
  int? time;

  @Property()
  String? tosUrl;

  @Property()
  String nutsJson;

  DbCashuMintInfo({
    this.name,
    this.version,
    this.description,
    this.descriptionLong,
    required this.contactJson,
    this.motd,
    this.iconUrl,
    required this.urls,
    this.time,
    this.tosUrl,
    required this.nutsJson,
  });

  factory DbCashuMintInfo.fromNdk(ndk_entities.CashuMintInfo ndkM) {
    final dbM = DbCashuMintInfo(
        name: ndkM.name,
        version: ndkM.version,
        description: ndkM.description,
        descriptionLong: ndkM.descriptionLong,
        contactJson: jsonEncode(ndkM.contact),
        motd: ndkM.motd,
        iconUrl: ndkM.iconUrl,
        urls: ndkM.urls,
        time: ndkM.time,
        tosUrl: ndkM.tosUrl,
        nutsJson: jsonEncode(ndkM.nuts));

    return dbM;
  }

  ndk_entities.CashuMintInfo toNdk() {
    final ndkM = ndk_entities.CashuMintInfo(
      name: name,
      version: version,
      description: description,
      descriptionLong: descriptionLong,
      contact: (jsonDecode(contactJson) as List)
          .map((e) => ndk_entities.CashuMintContact.fromJson(e))
          .toList(),
      motd: motd,
      iconUrl: iconUrl,
      urls: urls,
      time: time,
      tosUrl: tosUrl,
      nuts: (jsonDecode(nutsJson) as Map<String, dynamic>).map(
        (key, value) =>
            MapEntry(int.parse(key), ndk_entities.CashuMintNut.fromJson(value)),
      ),
    );

    return ndkM;
  }
}
