import 'package:objectbox/objectbox.dart';
import 'package:ndk/ndk.dart';

@Entity()
class DbFilterFetchedRangeRecord {
  @Id()
  int dbId = 0;

  /// Hash of the filter (without since/until)
  @Index()
  @Property()
  late String filterHash;

  /// The relay URL
  @Index()
  @Property()
  late String relayUrl;

  /// Start of the covered range
  @Property()
  late int rangeStart;

  /// End of the covered range
  @Property()
  late int rangeEnd;

  DbFilterFetchedRangeRecord({
    required this.filterHash,
    required this.relayUrl,
    required this.rangeStart,
    required this.rangeEnd,
  });

  FilterFetchedRangeRecord toNdk() {
    return FilterFetchedRangeRecord(
      filterHash: filterHash,
      relayUrl: relayUrl,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );
  }

  factory DbFilterFetchedRangeRecord.fromNdk(FilterFetchedRangeRecord record) {
    return DbFilterFetchedRangeRecord(
      filterHash: record.filterHash,
      relayUrl: record.relayUrl,
      rangeStart: record.rangeStart,
      rangeEnd: record.rangeEnd,
    );
  }
}
