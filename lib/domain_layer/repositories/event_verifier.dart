import '../entities/nip_01_event.dart';

abstract class EventVerifier {
  Future<bool> verify(Nip01Event event);
}
