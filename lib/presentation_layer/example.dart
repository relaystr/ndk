import 'package:dart_ndk/data_layer/repositories/verifiers/bip340_event_verifier.dart';
import 'package:dart_ndk/domain_layer/repositories/event_verifier_repository.dart';
import 'package:dart_ndk/presentation_layer/api.dart';
import 'package:dart_ndk/presentation_layer/request_config.dart';

//? how a user might use the api
class Example {
  OurApi globalNDKobj = OurApi({"some": "config"});
  EventVerifierRepository eventVerifier = Bip340EventVerifierRepositoryImpl();

  main() async {
    dynamic imposterFilter = {"pretend this is a valid filter", "some data"};

    var myRequest = RequestConfig.query(
      "myrequest",
      filters: imposterFilter,
      eventVerifier: eventVerifier,
    );

    var myResponse = await globalNDKobj.requestNostrEvent(myRequest).toList();
  }
}
