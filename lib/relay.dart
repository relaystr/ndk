import 'package:dart_ndk/relay_info.dart';
import 'package:dart_ndk/relay_stats.dart';

class Relay {
  String url;
  bool connecting = false;
  RelayInfo? info;
  RelayStats? stats;

  Relay(this.url);

  bool supportsNip(int nip) {
    return info!=null && info!.nips.contains(nip);
  }

  static RegExp RELAY_URL_REGEX = RegExp(
      r'^(wss?:\/\/)([0-9]{1,3}(?:\.[0-9]{1,3}){3}|[^:]+):?([0-9]{1,5})?$');

  static String? clean(String adr) {
    if (adr.endsWith("/")) {
      adr = adr.substring(0, adr.length - 1);
    }
    if (adr.contains("%")) {
      adr = Uri.decodeComponent(adr);
    }
    adr = adr.trim();
    if (!adr.contains(RELAY_URL_REGEX)) {
      return null;
    }
    return adr;
  }
}