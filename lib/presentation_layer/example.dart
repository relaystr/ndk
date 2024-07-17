import 'package:dart_ndk/dart_ndk.dart';
import 'package:dart_ndk/presentation_layer/api.dart';

//? how a user might use the api
class Example {
  OurApi globalNDKobj = OurApi(
    NdkConfig(
      eventVerifier: Bip340EventVerifier(),
      cache: MemCacheManager(),
      engine: NdkEngine.JIT,
    ),
  );

  main() async {
    dynamic imposterFilter = {"pretend this is a valid filter", "some data"};

    var myRequest = NdkRequest.query(
      "myrequest",
      filters: imposterFilter,
    );

    final myResponse = await globalNDKobj.requestNostrEvent(myRequest);
    final stream = myResponse.stream;
  }
}
