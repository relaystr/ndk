import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../objectbox.g.dart'; // created by `flutter pub run build_runner build`

class ObjectBoxInit {
  /// The Store of this app.
  late final Store store;

  ObjectBoxInit._create(this.store) {
    // Add any additional setup code, e.g. build queries.
  }

  /// Create an instance of ObjectBox to use throughout the app.
  /// [directory] optional custom directory for the database (useful for testing)
  static Future<ObjectBoxInit> create({String? directory}) async {
    final String dbPath;
    if (directory != null) {
      dbPath = directory;
    } else {
      final docsDir = await getApplicationDocumentsDirectory();
      dbPath = p.join(docsDir.path, "ndk-obx-default");
    }
    // Future<Store> openStore() {...} is defined in the generated objectbox.g.dart
    final store = await openStore(directory: dbPath);
    return ObjectBoxInit._create(store);
  }

  /// attaches to a existing running db, usefull for isolates
  static Future<ObjectBoxInit> attach({String? directory}) async {
    final String dbPath;
    if (directory != null) {
      dbPath = directory;
    } else {
      final docsDir = await getApplicationDocumentsDirectory();
      dbPath = p.join(docsDir.path, "ndk-obx-default");
    }

    final store = Store.attach(getObjectBoxModel(), dbPath);

    return ObjectBoxInit._create(store);
  }
}
