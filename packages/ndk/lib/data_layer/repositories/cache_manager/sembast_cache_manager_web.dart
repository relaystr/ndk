import 'package:sembast/sembast.dart' as sembast;

// Conditional import for sembast_web - this allows the file to be analyzed
// but will only be used on web platforms
import 'package:sembast/sembast_io.dart'
    if (dart.library.html) 'package:sembast_web/sembast_web.dart';

/// Database factory for web platform using sembast_web
final databaseFactory = databaseFactoryIo;

/// Open a database on web platform (databasePath is ignored)
Future<sembast.Database> openDatabase({
  String? databasePath,
  required String databaseName,
}) {
  return databaseFactory.openDatabase(databaseName);
}
