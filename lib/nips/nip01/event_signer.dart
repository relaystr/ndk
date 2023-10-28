import 'package:dart_ndk/nips/nip01/event.dart';

abstract class EventSigner {

  Future<void> sign(Nip01Event event);
}