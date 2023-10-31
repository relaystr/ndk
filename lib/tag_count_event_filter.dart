import 'package:dart_ndk/event_filter.dart';
import 'package:dart_ndk/nips/nip01/event.dart';

class TagCountEventFilter extends EventFilter {
  int maxTagCount;

  TagCountEventFilter(this.maxTagCount);

  @override
  bool filter(Nip01Event event) {
    return event.tags.length <= maxTagCount;
  }
}