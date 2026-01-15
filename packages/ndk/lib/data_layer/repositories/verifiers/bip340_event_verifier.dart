import 'dart:isolate';

import 'package:bip340/bip340.dart' as bip340;

import '../../../domain_layer/entities/nip_01_event.dart';
import '../../../domain_layer/entities/nip_01_utils.dart';
import '../../../domain_layer/repositories/event_verifier.dart';

/// Pure dart event verifier using https://pub.dev/packages/bip340
/// can be slow on mobile devices
class Bip340EventVerifier implements EventVerifier {
  bool useIsolate = true;

  Bip340EventVerifier({this.useIsolate = true});

  @override
  Future<bool> verify(Nip01Event event) async {
    if (event.sig == null) {
      return false;
    }
    if (!Nip01Utils.isIdValid(event)) return false;
    return useIsolate? await Isolate.run(() {
      return bip340.verify(event.pubKey, event.id, event.sig!);
    }) : bip340.verify(event.pubKey, event.id, event.sig!);
  }
}
