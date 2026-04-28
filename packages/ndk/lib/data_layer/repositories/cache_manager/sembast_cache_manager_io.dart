import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sembast/sembast.dart' as sembast;
import 'package:sembast/sembast_io.dart';

/// Database factory for native platforms using sembast_io
final databaseFactory = databaseFactoryIo;

/// Open a database on native platforms
Future<sembast.Database> openDatabase({
  required String databasePath,
  required String databaseName,
}) async {
  await Directory(databasePath).create(recursive: true);
  final dbFileName = "$databaseName.db";
  final dbPath = p.join(databasePath, dbFileName);
  return databaseFactory.openDatabase(dbPath);
}
