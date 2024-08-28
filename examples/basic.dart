import 'package:ndk/ndk.dart';
import 'package:ndk/presentation_layer/request_response.dart';

void main(List<String> arguments) async {
  Ndk ndk = Ndk(NdkConfig(
    eventVerifier: Bip340EventVerifier(),
    cache: MemCacheManager(),
  ));
  NdkResponse response = ndk.requests.query(filters: [
    Filter(kinds: [Nip01Event.TEXT_NODE_KIND], limit: 10)
  ]);

  await for (final event in response.stream) {
      print(event);
  }
}
