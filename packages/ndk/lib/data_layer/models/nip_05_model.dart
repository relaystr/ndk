import 'package:ndk/domain_layer/entities/nip_05.dart';

/// model for converting json <==> dart object
class Nip05Model extends Nip05 {
  /// creates a new [Nip05Model] instance
  Nip05Model({
    required super.pubKey,
    required super.nip05,
    super.valid,
    super.networkFetchTime,
    super.relays,
  });
}
