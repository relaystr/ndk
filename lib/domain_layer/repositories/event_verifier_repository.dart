import 'package:dart_ndk/domain_layer/entities/nip_01_event.dart';

abstract class EventVerifierRepository {
  Future<bool> verify(Nip01Event event);
}
