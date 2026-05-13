import '../nip_01_event.dart';

class CashuEvent {
  static const int kWalletKind = 17375;

  final String walletPrivkey;
  final Set<String> mints;

  final String userPubkey;

  late final Nip01Event? nostrEvent;

  CashuEvent({
    required this.walletPrivkey,
    required this.mints,
    required this.userPubkey,
    Nip01Event? nostrEvent,
  }) {
    if (nostrEvent != null) {
      this.nostrEvent = nostrEvent;
      return;
    }
  }
}
