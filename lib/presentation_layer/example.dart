import 'package:dart_ndk/data_layer/repositories/verifiers/bip340_event_verifier.dart';
import 'package:dart_ndk/domain_layer/repositories/event_verifier_repository.dart';
import 'package:dart_ndk/presentation_layer/api.dart';
import 'package:dart_ndk/presentation_layer/ndk_request.dart';

//? how a user might use the api
class Example {
  OurApi globalNDKobj = OurApi({"some": "config"});
  EventVerifier eventVerifier = Bip340EventVerifier();

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
