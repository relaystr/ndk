import 'package:isar/isar.dart';

import 'db_pubkey_mapping.dart';

part 'db_relay_set_item.g.dart';

@embedded
class DbRelaySetItem {
  String url;
  List<DbPubkeyMapping> pubKeyMappings;

  DbRelaySetItem(this.url, this.pubKeyMappings);
}
