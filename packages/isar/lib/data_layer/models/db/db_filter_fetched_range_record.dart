import 'package:isar/isar.dart';
import 'package:ndk/ndk.dart';

part 'db_filter_fetched_range_record.g.dart';

@Collection()
class DbFilterFetchedRangeRecord {
  /// Unique key: filterHash:relayUrl:rangeStart
  String get id => '$filterHash:$relayUrl:$rangeStart';

  @Index()
  final String filterHash;

  @Index()
  final String relayUrl;

  final int rangeStart;

  final int rangeEnd;

  DbFilterFetchedRangeRecord({
    required this.filterHash,
    required this.relayUrl,
    required this.rangeStart,
    required this.rangeEnd,
  });

  static DbFilterFetchedRangeRecord fromFilterFetchedRangeRecord(
      FilterFetchedRangeRecord record) {
    return DbFilterFetchedRangeRecord(
      filterHash: record.filterHash,
      relayUrl: record.relayUrl,
      rangeStart: record.rangeStart,
      rangeEnd: record.rangeEnd,
    );
  }

  FilterFetchedRangeRecord toFilterFetchedRangeRecord() {
    return FilterFetchedRangeRecord(
      filterHash: filterHash,
      relayUrl: relayUrl,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );
  }
}
