// GENERATED CODE - DO NOT MODIFY BY HAND
// This code was generated by ObjectBox. To update it run the generator again
// with `dart run build_runner build`.
// See also https://docs.objectbox.io/getting-started#generate-objectbox-code

// ignore_for_file: camel_case_types, depend_on_referenced_packages
// coverage:ignore-file

import 'dart:typed_data';

import 'package:flat_buffers/flat_buffers.dart' as fb;
import 'package:objectbox/internal.dart'
    as obx_int; // generated code can access "internal" functionality
import 'package:objectbox/objectbox.dart' as obx;
import 'package:objectbox_flutter_libs/objectbox_flutter_libs.dart';

import 'data_layer/db/object_box/schema/db_contact_list.dart';
import 'data_layer/db/object_box/schema/db_metadata.dart';
import 'data_layer/db/object_box/schema/db_nip_01_event.dart';
import 'data_layer/db/object_box/schema/db_nip_05.dart';
import 'data_layer/db/object_box/schema/db_user_relay_list.dart';

export 'package:objectbox/objectbox.dart'; // so that callers only have to import this file

final _entities = <obx_int.ModelEntity>[
  obx_int.ModelEntity(
      id: const obx_int.IdUid(1, 7267168510261043026),
      name: 'DbContactList',
      lastPropertyId: const obx_int.IdUid(11, 1117239018948887115),
      flags: 0,
      properties: <obx_int.ModelProperty>[
        obx_int.ModelProperty(
            id: const obx_int.IdUid(1, 6986744434432699288),
            name: 'dbId',
            type: 6,
            flags: 1),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(2, 1357400473715190005),
            name: 'pubKey',
            type: 9,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(3, 5247455000660751531),
            name: 'contacts',
            type: 30,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(4, 7259358756009996880),
            name: 'contactRelays',
            type: 30,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(5, 4273369131818739468),
            name: 'petnames',
            type: 30,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(6, 2282344906672001423),
            name: 'followedTags',
            type: 30,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(7, 4195168652292271612),
            name: 'followedCommunities',
            type: 30,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(8, 3312722063406963894),
            name: 'followedEvents',
            type: 30,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(9, 1828915220935170355),
            name: 'createdAt',
            type: 6,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(10, 662334951917934052),
            name: 'loadedTimestamp',
            type: 6,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(11, 1117239018948887115),
            name: 'sources',
            type: 30,
            flags: 0)
      ],
      relations: <obx_int.ModelRelation>[],
      backlinks: <obx_int.ModelBacklink>[]),
  obx_int.ModelEntity(
      id: const obx_int.IdUid(2, 530428573583615038),
      name: 'DbMetadata',
      lastPropertyId: const obx_int.IdUid(15, 3659729329624536988),
      flags: 0,
      properties: <obx_int.ModelProperty>[
        obx_int.ModelProperty(
            id: const obx_int.IdUid(1, 6311528020388961921),
            name: 'dbId',
            type: 6,
            flags: 1),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(2, 7481035913984486655),
            name: 'pubKey',
            type: 9,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(3, 9172997580341748819),
            name: 'name',
            type: 9,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(4, 3546373795758858754),
            name: 'displayName',
            type: 9,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(5, 3230539604094051327),
            name: 'picture',
            type: 9,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(6, 3084473881747351979),
            name: 'banner',
            type: 9,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(7, 2993268374284627402),
            name: 'website',
            type: 9,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(8, 2895930692931049587),
            name: 'about',
            type: 9,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(9, 2125436107011149884),
            name: 'nip05',
            type: 9,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(10, 1537952694209901022),
            name: 'lud16',
            type: 9,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(11, 4250356651761253102),
            name: 'lud06',
            type: 9,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(12, 4824960073052435758),
            name: 'updatedAt',
            type: 6,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(13, 1741276455180885874),
            name: 'refreshedTimestamp',
            type: 6,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(14, 1086893591781785038),
            name: 'splitDisplayNameWords',
            type: 30,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(15, 3659729329624536988),
            name: 'splitNameWords',
            type: 30,
            flags: 0)
      ],
      relations: <obx_int.ModelRelation>[],
      backlinks: <obx_int.ModelBacklink>[]),
  obx_int.ModelEntity(
      id: const obx_int.IdUid(3, 7160354677947505848),
      name: 'DbNip01Event',
      lastPropertyId: const obx_int.IdUid(10, 6188110795031782335),
      flags: 0,
      properties: <obx_int.ModelProperty>[
        obx_int.ModelProperty(
            id: const obx_int.IdUid(1, 1845247413054177411),
            name: 'dbId',
            type: 6,
            flags: 1),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(2, 3881479899267615466),
            name: 'nostrId',
            type: 9,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(3, 906982549236467078),
            name: 'pubKey',
            type: 9,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(4, 4024855326378855057),
            name: 'createdAt',
            type: 6,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(5, 8369487538579223995),
            name: 'kind',
            type: 6,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(6, 4676453295471475548),
            name: 'content',
            type: 9,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(7, 9113759858694952977),
            name: 'sig',
            type: 9,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(8, 2027711114854456160),
            name: 'validSig',
            type: 1,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(9, 7564063012610719918),
            name: 'sources',
            type: 30,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(10, 6188110795031782335),
            name: 'dbTags',
            type: 30,
            flags: 0)
      ],
      relations: <obx_int.ModelRelation>[],
      backlinks: <obx_int.ModelBacklink>[]),
  obx_int.ModelEntity(
      id: const obx_int.IdUid(4, 3637320921488077827),
      name: 'DbTag',
      lastPropertyId: const obx_int.IdUid(4, 1024563472021235903),
      flags: 0,
      properties: <obx_int.ModelProperty>[
        obx_int.ModelProperty(
            id: const obx_int.IdUid(1, 2662554970568175356),
            name: 'id',
            type: 6,
            flags: 1),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(2, 7256594753475161899),
            name: 'key',
            type: 9,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(3, 7261401074391147060),
            name: 'value',
            type: 9,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(4, 1024563472021235903),
            name: 'marker',
            type: 9,
            flags: 0)
      ],
      relations: <obx_int.ModelRelation>[],
      backlinks: <obx_int.ModelBacklink>[]),
  obx_int.ModelEntity(
      id: const obx_int.IdUid(5, 1189162834702422075),
      name: 'DbNip05',
      lastPropertyId: const obx_int.IdUid(7, 8942013022024139638),
      flags: 0,
      properties: <obx_int.ModelProperty>[
        obx_int.ModelProperty(
            id: const obx_int.IdUid(1, 7969165770416025296),
            name: 'dbId',
            type: 6,
            flags: 1),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(2, 7645157164222799699),
            name: 'pubKey',
            type: 9,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(3, 7879974338560469443),
            name: 'nip05',
            type: 9,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(4, 5481522983626357888),
            name: 'valid',
            type: 1,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(6, 5240456446636403236),
            name: 'networkFetchTime',
            type: 6,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(7, 8942013022024139638),
            name: 'relays',
            type: 30,
            flags: 0)
      ],
      relations: <obx_int.ModelRelation>[],
      backlinks: <obx_int.ModelBacklink>[]),
  obx_int.ModelEntity(
      id: const obx_int.IdUid(6, 263734506821907740),
      name: 'DbUserRelayList',
      lastPropertyId: const obx_int.IdUid(5, 745081192237571667),
      flags: 0,
      properties: <obx_int.ModelProperty>[
        obx_int.ModelProperty(
            id: const obx_int.IdUid(1, 1592738392109903014),
            name: 'dbId',
            type: 6,
            flags: 1),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(2, 4136737139372327801),
            name: 'pubKey',
            type: 9,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(3, 3907673358109208090),
            name: 'createdAt',
            type: 6,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(4, 6745786677378578982),
            name: 'refreshedTimestamp',
            type: 6,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(5, 745081192237571667),
            name: 'relaysJson',
            type: 9,
            flags: 0)
      ],
      relations: <obx_int.ModelRelation>[],
      backlinks: <obx_int.ModelBacklink>[])
];

/// Shortcut for [obx.Store.new] that passes [getObjectBoxModel] and for Flutter
/// apps by default a [directory] using `defaultStoreDirectory()` from the
/// ObjectBox Flutter library.
///
/// Note: for desktop apps it is recommended to specify a unique [directory].
///
/// See [obx.Store.new] for an explanation of all parameters.
///
/// For Flutter apps, also calls `loadObjectBoxLibraryAndroidCompat()` from
/// the ObjectBox Flutter library to fix loading the native ObjectBox library
/// on Android 6 and older.
Future<obx.Store> openStore(
    {String? directory,
    int? maxDBSizeInKB,
    int? maxDataSizeInKB,
    int? fileMode,
    int? maxReaders,
    bool queriesCaseSensitiveDefault = true,
    String? macosApplicationGroup}) async {
  await loadObjectBoxLibraryAndroidCompat();
  return obx.Store(getObjectBoxModel(),
      directory: directory ?? (await defaultStoreDirectory()).path,
      maxDBSizeInKB: maxDBSizeInKB,
      maxDataSizeInKB: maxDataSizeInKB,
      fileMode: fileMode,
      maxReaders: maxReaders,
      queriesCaseSensitiveDefault: queriesCaseSensitiveDefault,
      macosApplicationGroup: macosApplicationGroup);
}

/// Returns the ObjectBox model definition for this project for use with
/// [obx.Store.new].
obx_int.ModelDefinition getObjectBoxModel() {
  final model = obx_int.ModelInfo(
      entities: _entities,
      lastEntityId: const obx_int.IdUid(6, 263734506821907740),
      lastIndexId: const obx_int.IdUid(0, 0),
      lastRelationId: const obx_int.IdUid(0, 0),
      lastSequenceId: const obx_int.IdUid(0, 0),
      retiredEntityUids: const [],
      retiredIndexUids: const [],
      retiredPropertyUids: const [4248118904091022656],
      retiredRelationUids: const [],
      modelVersion: 5,
      modelVersionParserMinimum: 5,
      version: 1);

  final bindings = <Type, obx_int.EntityDefinition>{
    DbContactList: obx_int.EntityDefinition<DbContactList>(
        model: _entities[0],
        toOneRelations: (DbContactList object) => [],
        toManyRelations: (DbContactList object) => {},
        getId: (DbContactList object) => object.dbId,
        setId: (DbContactList object, int id) {
          object.dbId = id;
        },
        objectToFB: (DbContactList object, fb.Builder fbb) {
          final pubKeyOffset = fbb.writeString(object.pubKey);
          final contactsOffset = fbb.writeList(
              object.contacts.map(fbb.writeString).toList(growable: false));
          final contactRelaysOffset = fbb.writeList(object.contactRelays
              .map(fbb.writeString)
              .toList(growable: false));
          final petnamesOffset = fbb.writeList(
              object.petnames.map(fbb.writeString).toList(growable: false));
          final followedTagsOffset = fbb.writeList(
              object.followedTags.map(fbb.writeString).toList(growable: false));
          final followedCommunitiesOffset = fbb.writeList(object
              .followedCommunities
              .map(fbb.writeString)
              .toList(growable: false));
          final followedEventsOffset = fbb.writeList(object.followedEvents
              .map(fbb.writeString)
              .toList(growable: false));
          final sourcesOffset = fbb.writeList(
              object.sources.map(fbb.writeString).toList(growable: false));
          fbb.startTable(12);
          fbb.addInt64(0, object.dbId);
          fbb.addOffset(1, pubKeyOffset);
          fbb.addOffset(2, contactsOffset);
          fbb.addOffset(3, contactRelaysOffset);
          fbb.addOffset(4, petnamesOffset);
          fbb.addOffset(5, followedTagsOffset);
          fbb.addOffset(6, followedCommunitiesOffset);
          fbb.addOffset(7, followedEventsOffset);
          fbb.addInt64(8, object.createdAt);
          fbb.addInt64(9, object.loadedTimestamp);
          fbb.addOffset(10, sourcesOffset);
          fbb.finish(fbb.endTable());
          return object.dbId;
        },
        objectFromFB: (obx.Store store, ByteData fbData) {
          final buffer = fb.BufferContext(fbData);
          final rootOffset = buffer.derefObject(0);
          final pubKeyParam = const fb.StringReader(asciiOptimization: true)
              .vTableGet(buffer, rootOffset, 6, '');
          final contactsParam = const fb.ListReader<String>(
                  fb.StringReader(asciiOptimization: true),
                  lazy: false)
              .vTableGet(buffer, rootOffset, 8, []);
          final object = DbContactList(
              pubKey: pubKeyParam, contacts: contactsParam)
            ..dbId = const fb.Int64Reader().vTableGet(buffer, rootOffset, 4, 0)
            ..contactRelays = const fb.ListReader<String>(
                    fb.StringReader(asciiOptimization: true),
                    lazy: false)
                .vTableGet(buffer, rootOffset, 10, [])
            ..petnames = const fb.ListReader<String>(
                    fb.StringReader(asciiOptimization: true),
                    lazy: false)
                .vTableGet(buffer, rootOffset, 12, [])
            ..followedTags = const fb.ListReader<String>(
                    fb.StringReader(asciiOptimization: true),
                    lazy: false)
                .vTableGet(buffer, rootOffset, 14, [])
            ..followedCommunities = const fb.ListReader<String>(
                    fb.StringReader(asciiOptimization: true),
                    lazy: false)
                .vTableGet(buffer, rootOffset, 16, [])
            ..followedEvents = const fb.ListReader<String>(
                    fb.StringReader(asciiOptimization: true),
                    lazy: false)
                .vTableGet(buffer, rootOffset, 18, [])
            ..createdAt =
                const fb.Int64Reader().vTableGet(buffer, rootOffset, 20, 0)
            ..loadedTimestamp =
                const fb.Int64Reader().vTableGetNullable(buffer, rootOffset, 22)
            ..sources = const fb.ListReader<String>(
                    fb.StringReader(asciiOptimization: true),
                    lazy: false)
                .vTableGet(buffer, rootOffset, 24, []);

          return object;
        }),
    DbMetadata: obx_int.EntityDefinition<DbMetadata>(
        model: _entities[1],
        toOneRelations: (DbMetadata object) => [],
        toManyRelations: (DbMetadata object) => {},
        getId: (DbMetadata object) => object.dbId,
        setId: (DbMetadata object, int id) {
          object.dbId = id;
        },
        objectToFB: (DbMetadata object, fb.Builder fbb) {
          final pubKeyOffset = fbb.writeString(object.pubKey);
          final nameOffset =
              object.name == null ? null : fbb.writeString(object.name!);
          final displayNameOffset = object.displayName == null
              ? null
              : fbb.writeString(object.displayName!);
          final pictureOffset =
              object.picture == null ? null : fbb.writeString(object.picture!);
          final bannerOffset =
              object.banner == null ? null : fbb.writeString(object.banner!);
          final websiteOffset =
              object.website == null ? null : fbb.writeString(object.website!);
          final aboutOffset =
              object.about == null ? null : fbb.writeString(object.about!);
          final nip05Offset =
              object.nip05 == null ? null : fbb.writeString(object.nip05!);
          final lud16Offset =
              object.lud16 == null ? null : fbb.writeString(object.lud16!);
          final lud06Offset =
              object.lud06 == null ? null : fbb.writeString(object.lud06!);
          final splitDisplayNameWordsOffset =
              object.splitDisplayNameWords == null
                  ? null
                  : fbb.writeList(object.splitDisplayNameWords!
                      .map(fbb.writeString)
                      .toList(growable: false));
          final splitNameWordsOffset = object.splitNameWords == null
              ? null
              : fbb.writeList(object.splitNameWords!
                  .map(fbb.writeString)
                  .toList(growable: false));
          fbb.startTable(16);
          fbb.addInt64(0, object.dbId);
          fbb.addOffset(1, pubKeyOffset);
          fbb.addOffset(2, nameOffset);
          fbb.addOffset(3, displayNameOffset);
          fbb.addOffset(4, pictureOffset);
          fbb.addOffset(5, bannerOffset);
          fbb.addOffset(6, websiteOffset);
          fbb.addOffset(7, aboutOffset);
          fbb.addOffset(8, nip05Offset);
          fbb.addOffset(9, lud16Offset);
          fbb.addOffset(10, lud06Offset);
          fbb.addInt64(11, object.updatedAt);
          fbb.addInt64(12, object.refreshedTimestamp);
          fbb.addOffset(13, splitDisplayNameWordsOffset);
          fbb.addOffset(14, splitNameWordsOffset);
          fbb.finish(fbb.endTable());
          return object.dbId;
        },
        objectFromFB: (obx.Store store, ByteData fbData) {
          final buffer = fb.BufferContext(fbData);
          final rootOffset = buffer.derefObject(0);
          final pubKeyParam = const fb.StringReader(asciiOptimization: true)
              .vTableGet(buffer, rootOffset, 6, '');
          final nameParam = const fb.StringReader(asciiOptimization: true)
              .vTableGetNullable(buffer, rootOffset, 8);
          final displayNameParam =
              const fb.StringReader(asciiOptimization: true)
                  .vTableGetNullable(buffer, rootOffset, 10);
          final splitNameWordsParam = const fb.ListReader<String>(
                  fb.StringReader(asciiOptimization: true),
                  lazy: false)
              .vTableGetNullable(buffer, rootOffset, 32);
          final splitDisplayNameWordsParam = const fb.ListReader<String>(
                  fb.StringReader(asciiOptimization: true),
                  lazy: false)
              .vTableGetNullable(buffer, rootOffset, 30);
          final pictureParam = const fb.StringReader(asciiOptimization: true)
              .vTableGetNullable(buffer, rootOffset, 12);
          final bannerParam = const fb.StringReader(asciiOptimization: true)
              .vTableGetNullable(buffer, rootOffset, 14);
          final websiteParam = const fb.StringReader(asciiOptimization: true)
              .vTableGetNullable(buffer, rootOffset, 16);
          final aboutParam = const fb.StringReader(asciiOptimization: true)
              .vTableGetNullable(buffer, rootOffset, 18);
          final nip05Param = const fb.StringReader(asciiOptimization: true)
              .vTableGetNullable(buffer, rootOffset, 20);
          final lud16Param = const fb.StringReader(asciiOptimization: true)
              .vTableGetNullable(buffer, rootOffset, 22);
          final lud06Param = const fb.StringReader(asciiOptimization: true)
              .vTableGetNullable(buffer, rootOffset, 24);
          final updatedAtParam =
              const fb.Int64Reader().vTableGetNullable(buffer, rootOffset, 26);
          final refreshedTimestampParam =
              const fb.Int64Reader().vTableGetNullable(buffer, rootOffset, 28);
          final object = DbMetadata(
              pubKey: pubKeyParam,
              name: nameParam,
              displayName: displayNameParam,
              splitNameWords: splitNameWordsParam,
              splitDisplayNameWords: splitDisplayNameWordsParam,
              picture: pictureParam,
              banner: bannerParam,
              website: websiteParam,
              about: aboutParam,
              nip05: nip05Param,
              lud16: lud16Param,
              lud06: lud06Param,
              updatedAt: updatedAtParam,
              refreshedTimestamp: refreshedTimestampParam)
            ..dbId = const fb.Int64Reader().vTableGet(buffer, rootOffset, 4, 0);

          return object;
        }),
    DbNip01Event: obx_int.EntityDefinition<DbNip01Event>(
        model: _entities[2],
        toOneRelations: (DbNip01Event object) => [],
        toManyRelations: (DbNip01Event object) => {},
        getId: (DbNip01Event object) => object.dbId,
        setId: (DbNip01Event object, int id) {
          object.dbId = id;
        },
        objectToFB: (DbNip01Event object, fb.Builder fbb) {
          final nostrIdOffset = fbb.writeString(object.nostrId);
          final pubKeyOffset = fbb.writeString(object.pubKey);
          final contentOffset = fbb.writeString(object.content);
          final sigOffset = fbb.writeString(object.sig);
          final sourcesOffset = fbb.writeList(
              object.sources.map(fbb.writeString).toList(growable: false));
          final dbTagsOffset = fbb.writeList(
              object.dbTags.map(fbb.writeString).toList(growable: false));
          fbb.startTable(11);
          fbb.addInt64(0, object.dbId);
          fbb.addOffset(1, nostrIdOffset);
          fbb.addOffset(2, pubKeyOffset);
          fbb.addInt64(3, object.createdAt);
          fbb.addInt64(4, object.kind);
          fbb.addOffset(5, contentOffset);
          fbb.addOffset(6, sigOffset);
          fbb.addBool(7, object.validSig);
          fbb.addOffset(8, sourcesOffset);
          fbb.addOffset(9, dbTagsOffset);
          fbb.finish(fbb.endTable());
          return object.dbId;
        },
        objectFromFB: (obx.Store store, ByteData fbData) {
          final buffer = fb.BufferContext(fbData);
          final rootOffset = buffer.derefObject(0);
          final pubKeyParam = const fb.StringReader(asciiOptimization: true)
              .vTableGet(buffer, rootOffset, 8, '');
          final kindParam =
              const fb.Int64Reader().vTableGet(buffer, rootOffset, 12, 0);
          final dbTagsParam = const fb.ListReader<String>(
                  fb.StringReader(asciiOptimization: true),
                  lazy: false)
              .vTableGet(buffer, rootOffset, 22, []);
          final contentParam = const fb.StringReader(asciiOptimization: true)
              .vTableGet(buffer, rootOffset, 14, '');
          final createdAtParam =
              const fb.Int64Reader().vTableGet(buffer, rootOffset, 10, 0);
          final object = DbNip01Event(
              pubKey: pubKeyParam,
              kind: kindParam,
              dbTags: dbTagsParam,
              content: contentParam,
              createdAt: createdAtParam)
            ..dbId = const fb.Int64Reader().vTableGet(buffer, rootOffset, 4, 0)
            ..nostrId = const fb.StringReader(asciiOptimization: true)
                .vTableGet(buffer, rootOffset, 6, '')
            ..sig = const fb.StringReader(asciiOptimization: true)
                .vTableGet(buffer, rootOffset, 16, '')
            ..validSig =
                const fb.BoolReader().vTableGetNullable(buffer, rootOffset, 18)
            ..sources = const fb.ListReader<String>(
                    fb.StringReader(asciiOptimization: true),
                    lazy: false)
                .vTableGet(buffer, rootOffset, 20, []);

          return object;
        }),
    DbTag: obx_int.EntityDefinition<DbTag>(
        model: _entities[3],
        toOneRelations: (DbTag object) => [],
        toManyRelations: (DbTag object) => {},
        getId: (DbTag object) => object.id,
        setId: (DbTag object, int id) {
          object.id = id;
        },
        objectToFB: (DbTag object, fb.Builder fbb) {
          final keyOffset = fbb.writeString(object.key);
          final valueOffset = fbb.writeString(object.value);
          final markerOffset =
              object.marker == null ? null : fbb.writeString(object.marker!);
          fbb.startTable(5);
          fbb.addInt64(0, object.id);
          fbb.addOffset(1, keyOffset);
          fbb.addOffset(2, valueOffset);
          fbb.addOffset(3, markerOffset);
          fbb.finish(fbb.endTable());
          return object.id;
        },
        objectFromFB: (obx.Store store, ByteData fbData) {
          final buffer = fb.BufferContext(fbData);
          final rootOffset = buffer.derefObject(0);
          final keyParam = const fb.StringReader(asciiOptimization: true)
              .vTableGet(buffer, rootOffset, 6, '');
          final valueParam = const fb.StringReader(asciiOptimization: true)
              .vTableGet(buffer, rootOffset, 8, '');
          final markerParam = const fb.StringReader(asciiOptimization: true)
              .vTableGetNullable(buffer, rootOffset, 10);
          final object = DbTag(
              key: keyParam, value: valueParam, marker: markerParam)
            ..id = const fb.Int64Reader().vTableGet(buffer, rootOffset, 4, 0);

          return object;
        }),
    DbNip05: obx_int.EntityDefinition<DbNip05>(
        model: _entities[4],
        toOneRelations: (DbNip05 object) => [],
        toManyRelations: (DbNip05 object) => {},
        getId: (DbNip05 object) => object.dbId,
        setId: (DbNip05 object, int id) {
          object.dbId = id;
        },
        objectToFB: (DbNip05 object, fb.Builder fbb) {
          final pubKeyOffset = fbb.writeString(object.pubKey);
          final nip05Offset = fbb.writeString(object.nip05);
          final relaysOffset = fbb.writeList(
              object.relays.map(fbb.writeString).toList(growable: false));
          fbb.startTable(8);
          fbb.addInt64(0, object.dbId);
          fbb.addOffset(1, pubKeyOffset);
          fbb.addOffset(2, nip05Offset);
          fbb.addBool(3, object.valid);
          fbb.addInt64(5, object.networkFetchTime);
          fbb.addOffset(6, relaysOffset);
          fbb.finish(fbb.endTable());
          return object.dbId;
        },
        objectFromFB: (obx.Store store, ByteData fbData) {
          final buffer = fb.BufferContext(fbData);
          final rootOffset = buffer.derefObject(0);
          final pubKeyParam = const fb.StringReader(asciiOptimization: true)
              .vTableGet(buffer, rootOffset, 6, '');
          final nip05Param = const fb.StringReader(asciiOptimization: true)
              .vTableGet(buffer, rootOffset, 8, '');
          final validParam =
              const fb.BoolReader().vTableGet(buffer, rootOffset, 10, false);
          final networkFetchTimeParam =
              const fb.Int64Reader().vTableGetNullable(buffer, rootOffset, 14);
          final relaysParam = const fb.ListReader<String>(
                  fb.StringReader(asciiOptimization: true),
                  lazy: false)
              .vTableGet(buffer, rootOffset, 16, []);
          final object = DbNip05(
              pubKey: pubKeyParam,
              nip05: nip05Param,
              valid: validParam,
              networkFetchTime: networkFetchTimeParam,
              relays: relaysParam)
            ..dbId = const fb.Int64Reader().vTableGet(buffer, rootOffset, 4, 0);

          return object;
        }),
    DbUserRelayList: obx_int.EntityDefinition<DbUserRelayList>(
        model: _entities[5],
        toOneRelations: (DbUserRelayList object) => [],
        toManyRelations: (DbUserRelayList object) => {},
        getId: (DbUserRelayList object) => object.dbId,
        setId: (DbUserRelayList object, int id) {
          object.dbId = id;
        },
        objectToFB: (DbUserRelayList object, fb.Builder fbb) {
          final pubKeyOffset = fbb.writeString(object.pubKey);
          final relaysJsonOffset = fbb.writeString(object.relaysJson);
          fbb.startTable(6);
          fbb.addInt64(0, object.dbId);
          fbb.addOffset(1, pubKeyOffset);
          fbb.addInt64(2, object.createdAt);
          fbb.addInt64(3, object.refreshedTimestamp);
          fbb.addOffset(4, relaysJsonOffset);
          fbb.finish(fbb.endTable());
          return object.dbId;
        },
        objectFromFB: (obx.Store store, ByteData fbData) {
          final buffer = fb.BufferContext(fbData);
          final rootOffset = buffer.derefObject(0);
          final pubKeyParam = const fb.StringReader(asciiOptimization: true)
              .vTableGet(buffer, rootOffset, 6, '');
          final relaysJsonParam = const fb.StringReader(asciiOptimization: true)
              .vTableGet(buffer, rootOffset, 12, '');
          final createdAtParam =
              const fb.Int64Reader().vTableGet(buffer, rootOffset, 8, 0);
          final refreshedTimestampParam =
              const fb.Int64Reader().vTableGet(buffer, rootOffset, 10, 0);
          final object = DbUserRelayList(
              pubKey: pubKeyParam,
              relaysJson: relaysJsonParam,
              createdAt: createdAtParam,
              refreshedTimestamp: refreshedTimestampParam)
            ..dbId = const fb.Int64Reader().vTableGet(buffer, rootOffset, 4, 0);

          return object;
        })
  };

  return obx_int.ModelDefinition(model, bindings);
}

/// [DbContactList] entity fields to define ObjectBox queries.
class DbContactList_ {
  /// See [DbContactList.dbId].
  static final dbId =
      obx.QueryIntegerProperty<DbContactList>(_entities[0].properties[0]);

  /// See [DbContactList.pubKey].
  static final pubKey =
      obx.QueryStringProperty<DbContactList>(_entities[0].properties[1]);

  /// See [DbContactList.contacts].
  static final contacts =
      obx.QueryStringVectorProperty<DbContactList>(_entities[0].properties[2]);

  /// See [DbContactList.contactRelays].
  static final contactRelays =
      obx.QueryStringVectorProperty<DbContactList>(_entities[0].properties[3]);

  /// See [DbContactList.petnames].
  static final petnames =
      obx.QueryStringVectorProperty<DbContactList>(_entities[0].properties[4]);

  /// See [DbContactList.followedTags].
  static final followedTags =
      obx.QueryStringVectorProperty<DbContactList>(_entities[0].properties[5]);

  /// See [DbContactList.followedCommunities].
  static final followedCommunities =
      obx.QueryStringVectorProperty<DbContactList>(_entities[0].properties[6]);

  /// See [DbContactList.followedEvents].
  static final followedEvents =
      obx.QueryStringVectorProperty<DbContactList>(_entities[0].properties[7]);

  /// See [DbContactList.createdAt].
  static final createdAt =
      obx.QueryIntegerProperty<DbContactList>(_entities[0].properties[8]);

  /// See [DbContactList.loadedTimestamp].
  static final loadedTimestamp =
      obx.QueryIntegerProperty<DbContactList>(_entities[0].properties[9]);

  /// See [DbContactList.sources].
  static final sources =
      obx.QueryStringVectorProperty<DbContactList>(_entities[0].properties[10]);
}

/// [DbMetadata] entity fields to define ObjectBox queries.
class DbMetadata_ {
  /// See [DbMetadata.dbId].
  static final dbId =
      obx.QueryIntegerProperty<DbMetadata>(_entities[1].properties[0]);

  /// See [DbMetadata.pubKey].
  static final pubKey =
      obx.QueryStringProperty<DbMetadata>(_entities[1].properties[1]);

  /// See [DbMetadata.name].
  static final name =
      obx.QueryStringProperty<DbMetadata>(_entities[1].properties[2]);

  /// See [DbMetadata.displayName].
  static final displayName =
      obx.QueryStringProperty<DbMetadata>(_entities[1].properties[3]);

  /// See [DbMetadata.picture].
  static final picture =
      obx.QueryStringProperty<DbMetadata>(_entities[1].properties[4]);

  /// See [DbMetadata.banner].
  static final banner =
      obx.QueryStringProperty<DbMetadata>(_entities[1].properties[5]);

  /// See [DbMetadata.website].
  static final website =
      obx.QueryStringProperty<DbMetadata>(_entities[1].properties[6]);

  /// See [DbMetadata.about].
  static final about =
      obx.QueryStringProperty<DbMetadata>(_entities[1].properties[7]);

  /// See [DbMetadata.nip05].
  static final nip05 =
      obx.QueryStringProperty<DbMetadata>(_entities[1].properties[8]);

  /// See [DbMetadata.lud16].
  static final lud16 =
      obx.QueryStringProperty<DbMetadata>(_entities[1].properties[9]);

  /// See [DbMetadata.lud06].
  static final lud06 =
      obx.QueryStringProperty<DbMetadata>(_entities[1].properties[10]);

  /// See [DbMetadata.updatedAt].
  static final updatedAt =
      obx.QueryIntegerProperty<DbMetadata>(_entities[1].properties[11]);

  /// See [DbMetadata.refreshedTimestamp].
  static final refreshedTimestamp =
      obx.QueryIntegerProperty<DbMetadata>(_entities[1].properties[12]);

  /// See [DbMetadata.splitDisplayNameWords].
  static final splitDisplayNameWords =
      obx.QueryStringVectorProperty<DbMetadata>(_entities[1].properties[13]);

  /// See [DbMetadata.splitNameWords].
  static final splitNameWords =
      obx.QueryStringVectorProperty<DbMetadata>(_entities[1].properties[14]);
}

/// [DbNip01Event] entity fields to define ObjectBox queries.
class DbNip01Event_ {
  /// See [DbNip01Event.dbId].
  static final dbId =
      obx.QueryIntegerProperty<DbNip01Event>(_entities[2].properties[0]);

  /// See [DbNip01Event.nostrId].
  static final nostrId =
      obx.QueryStringProperty<DbNip01Event>(_entities[2].properties[1]);

  /// See [DbNip01Event.pubKey].
  static final pubKey =
      obx.QueryStringProperty<DbNip01Event>(_entities[2].properties[2]);

  /// See [DbNip01Event.createdAt].
  static final createdAt =
      obx.QueryIntegerProperty<DbNip01Event>(_entities[2].properties[3]);

  /// See [DbNip01Event.kind].
  static final kind =
      obx.QueryIntegerProperty<DbNip01Event>(_entities[2].properties[4]);

  /// See [DbNip01Event.content].
  static final content =
      obx.QueryStringProperty<DbNip01Event>(_entities[2].properties[5]);

  /// See [DbNip01Event.sig].
  static final sig =
      obx.QueryStringProperty<DbNip01Event>(_entities[2].properties[6]);

  /// See [DbNip01Event.validSig].
  static final validSig =
      obx.QueryBooleanProperty<DbNip01Event>(_entities[2].properties[7]);

  /// See [DbNip01Event.sources].
  static final sources =
      obx.QueryStringVectorProperty<DbNip01Event>(_entities[2].properties[8]);

  /// See [DbNip01Event.dbTags].
  static final dbTags =
      obx.QueryStringVectorProperty<DbNip01Event>(_entities[2].properties[9]);
}

/// [DbTag] entity fields to define ObjectBox queries.
class DbTag_ {
  /// See [DbTag.id].
  static final id = obx.QueryIntegerProperty<DbTag>(_entities[3].properties[0]);

  /// See [DbTag.key].
  static final key = obx.QueryStringProperty<DbTag>(_entities[3].properties[1]);

  /// See [DbTag.value].
  static final value =
      obx.QueryStringProperty<DbTag>(_entities[3].properties[2]);

  /// See [DbTag.marker].
  static final marker =
      obx.QueryStringProperty<DbTag>(_entities[3].properties[3]);
}

/// [DbNip05] entity fields to define ObjectBox queries.
class DbNip05_ {
  /// See [DbNip05.dbId].
  static final dbId =
      obx.QueryIntegerProperty<DbNip05>(_entities[4].properties[0]);

  /// See [DbNip05.pubKey].
  static final pubKey =
      obx.QueryStringProperty<DbNip05>(_entities[4].properties[1]);

  /// See [DbNip05.nip05].
  static final nip05 =
      obx.QueryStringProperty<DbNip05>(_entities[4].properties[2]);

  /// See [DbNip05.valid].
  static final valid =
      obx.QueryBooleanProperty<DbNip05>(_entities[4].properties[3]);

  /// See [DbNip05.networkFetchTime].
  static final networkFetchTime =
      obx.QueryIntegerProperty<DbNip05>(_entities[4].properties[4]);

  /// See [DbNip05.relays].
  static final relays =
      obx.QueryStringVectorProperty<DbNip05>(_entities[4].properties[5]);
}

/// [DbUserRelayList] entity fields to define ObjectBox queries.
class DbUserRelayList_ {
  /// See [DbUserRelayList.dbId].
  static final dbId =
      obx.QueryIntegerProperty<DbUserRelayList>(_entities[5].properties[0]);

  /// See [DbUserRelayList.pubKey].
  static final pubKey =
      obx.QueryStringProperty<DbUserRelayList>(_entities[5].properties[1]);

  /// See [DbUserRelayList.createdAt].
  static final createdAt =
      obx.QueryIntegerProperty<DbUserRelayList>(_entities[5].properties[2]);

  /// See [DbUserRelayList.refreshedTimestamp].
  static final refreshedTimestamp =
      obx.QueryIntegerProperty<DbUserRelayList>(_entities[5].properties[3]);

  /// See [DbUserRelayList.relaysJson].
  static final relaysJson =
      obx.QueryStringProperty<DbUserRelayList>(_entities[5].properties[4]);
}
