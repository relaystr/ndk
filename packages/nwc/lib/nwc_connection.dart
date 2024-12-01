import 'dart:async';

import 'package:bip340/bip340.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_nwc/commands/get_info_response.dart';
import 'package:ndk_nwc/commands/nwc_response.dart';
import 'package:ndk_nwc/nosrt_wallet_connect_uri.dart';

class NwcConnection {
  NostrWalletConnectUri uri;
  EventSigner? _signer;
  GetInfoResponse? info;
  NdkResponse? subscription;
  StreamController<NwcResponse> responseStream =
      StreamController<NwcResponse>();
  StreamController<NwcResponse> notificationStream =
      StreamController<NwcResponse>();

  List<String> supportedVersions = ["0.0"];

  Set<String> permissions = {};

  NwcConnection(this.uri);

  EventSigner get signer {
    if (_signer == null) {
      _signer = Bip340EventSigner(
          privateKey: uri.secret, publicKey: getPublicKey(uri.secret));
    }
    return _signer!;
  }

  bool isLegacyNotifications() {
    return supportedVersions.length == 1 && supportedVersions.first == "0.0" ||
        !supportedVersions.any((e) => e != "0.0");
  }
}
