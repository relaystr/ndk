import 'package:sembast/sembast.dart' as sembast;
import 'package:sembast_web/sembast_web.dart';

/// Database factory for web platform using sembast_web
final databaseFactory = databaseFactoryWeb;

/// Open a database on web platform (databasePath is ignored)
Future<sembast.Database> openDatabase({
  String? databasePath,
  required String databaseName,
}) async {
  return databaseFactory.openDatabase(databaseName);
}
