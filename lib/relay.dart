import 'package:dart_ndk/relay_info.dart';
import 'package:dart_ndk/relay_stats.dart';

class Relay {
  String url;
  RelayInfo? info;
  RelayStats? stats;

  Relay(this.url);

  bool supportsNip(int nip) {
    return info!=null && info!.nips.contains(nip);
  }
}