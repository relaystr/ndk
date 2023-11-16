import 'package:dart_ndk/event_filter.dart';
import 'package:dart_ndk/nips/nip01/event.dart';

import 'nips/nip02/contact_list.dart';

class TagCountEventFilter extends EventFilter {
  int maxTagCount;

  TagCountEventFilter(this.maxTagCount);

  @override
  bool filter(Nip01Event event) {
    return event.kind==ContactList.KIND || event.tags.length <= maxTagCount;
  }
}