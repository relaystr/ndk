import 'package:ndk/domain_layer/entities/event_filter.dart';
import 'package:ndk/domain_layer/entities/nip_01_event.dart';

import 'domain_layer/entities/contact_list.dart';
import 'domain_layer/entities/nip_65.dart';

/// filter for too many tags
class PTagCountEventFilter extends EventFilter {
  int maxTagCount;

  PTagCountEventFilter(this.maxTagCount);

  @override
  bool filter(Nip01Event event) {
    return event.kind == ContactList.KIND ||
        event.kind == Nip65.KIND ||
        event.pTags.length <= maxTagCount;
  }
}
