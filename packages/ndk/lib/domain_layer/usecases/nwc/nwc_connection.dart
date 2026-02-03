import 'dart:async';

import 'package:bip340/bip340.dart';
import 'package:ndk/ndk.dart';
import 'nostr_wallet_connect_uri.dart';
import 'nwc_notification.dart';

import 'responses/nwc_response.dart';

/// NWC Connection
class NwcConnection {
  NostrWalletConnectUri uri;
  EventSigner? _signer;
  GetInfoResponse? info;
  NdkResponse? subscription;
  StreamSubscription<Nip01Event>? _streamSubscription;

  bool useETagForEachRequest = false;
  bool ignoreCapabilitiesCheck = false;

  StreamController<NwcResponse> responseStream =
      StreamController<NwcResponse>.broadcast();

  StreamController<NwcNotification> notificationStream =
      StreamController<NwcNotification>.broadcast();

  Stream<NwcNotification> get paymentsReceivedStream =>
      notificationStream.stream
          .where((notification) => notification.isPaymentReceived)
          .asBroadcastStream();

  Stream<NwcNotification> get paymentsSentStream => notificationStream.stream
      .where((notification) => notification.isPaymentSent)
      .asBroadcastStream();

  Stream<NwcNotification> get holdInvoiceStateStream =>
      notificationStream.stream
          .where((notification) => notification.isHoldInvoiceAccepted)
          .asBroadcastStream();

  /// listen
  void listen(void Function(Nip01Event event)? onData) {
    if (subscription != null) {
      _streamSubscription = subscription!.stream.listen(onData);
    } else {
      Logger.log
          .e("NwcConnection: Attempted to listen on a null subscription.");
    }
  }

  /// cancels subscription and closes stream controllers
  Future<void> close() async {
    if (_streamSubscription != null) {
      await _streamSubscription!.cancel();
    }
    await responseStream.close();
    await notificationStream.close();
  }

  List<String> supportedVersions = ["0.0"];
  List<String> supportedEncryptions = ["nip04"];

  Set<String> permissions = {};

  NwcConnection(this.uri);

  EventSigner get signer {
    _signer ??= Bip340EventSigner(
        privateKey: uri.secret, publicKey: getPublicKey(uri.secret));
    return _signer!;
  }

  /// Get all relays for this connection
  List<String> get relays => uri.relays;

  /// Get the primary relay (first in the list, for backward compatibility)
  @Deprecated('Use relays list instead')
  String get relay => uri.relays.isNotEmpty ? uri.relays.first : '';

  /// does this connection only support legacy notifications
  bool isLegacyNotifications() {
    return (supportedVersions.length == 1 && supportedVersions.first == "0.0" ||
            !supportedVersions.any((e) => e != "0.0")) &&
        !supportedEncryptions.any((e) => e != "nip04");
  }

  @override
  String toString() {
    return 'NwcConnection{uri: $uri}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NwcConnection &&
          runtimeType == other.runtimeType &&
          uri == other.uri;

  @override
  int get hashCode => uri.hashCode;
}
