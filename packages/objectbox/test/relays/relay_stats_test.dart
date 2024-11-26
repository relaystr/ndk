import 'package:ndk/domain_layer/entities/relay_stats.dart';
import 'package:test/test.dart';

void main() async {
  test('stats', () async {
    RelayStats stats = RelayStats();
    expect(0, stats.getTotalEventsRead());
    expect(0, stats.getTotalBytesRead());
  });
}
