import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/helpers.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:ndk/domain_layer/entities/nip_65.dart';
import 'package:test/test.dart';
import 'dart:developer' as developer;
import '../../mocks/mock_event_verifier.dart';

void main() async {
  group(
    "Calculate best relays (external REAL)",
    skip: true,
    () {
      calculateBestRelaysForNpubContactsFeed(String npub,
          {int relayMinCountPerPubKey = 2}) async {
        CacheManager cacheManager = MemCacheManager();

        final ndk = Ndk(NdkConfig(
          eventVerifier: MockEventVerifier(),
          cache: cacheManager,
          engine: NdkEngine.JIT,
        ));

        // wait for the relays to connect
        await Future.delayed(const Duration(seconds: 2));

        final key = KeyPair.justPublicKey(Helpers.decodeBech32(npub)[0]);

        final contactsResponse = ndk.requests.query(name: "contacts", filters: [
          Filter(authors: [key.publicKey], kinds: [ContactList.KIND]),
        ]);

        var responseList = await contactsResponse.stream.toList();

        List<ContactList> contactLists =
            responseList.map((event) => ContactList.fromEvent(event)).toList();

        cacheManager.saveContactLists(contactLists);

        ContactList? myContactList =
            await cacheManager.loadContactList(key.publicKey);
        expect(myContactList, isNotNull);

        // get nip65 data

        NdkResponse nip65Response = ndk.requests.query(name: "nip65", filters: [
          Filter(authors: myContactList!.contacts, kinds: [Nip65.KIND]),
        ]);

        var nip65events = await nip65Response.stream.toList();
        cacheManager.saveEvents(nip65events);

        cacheManager.loadEvents(
          pubKeys: myContactList.contacts,
          kinds: [Nip65.KIND],
        );

        developer.log('##################################################');

        ndk.requests.query(name: "feed-test", filters: [
          Filter(
            authors: myContactList.contacts,
            kinds: [Nip01Event.TEXT_NODE_KIND],
            since:
                (DateTime.now().millisecondsSinceEpoch ~/ 1000) - 60 * 60 * 1,
          ),
        ]);

        await Future.delayed(const Duration(seconds: 5));

        NdkResponse feedResponse2 =
            ndk.requests.subscription(id: "feed-test2", filters: [
          Filter(
            authors: myContactList.contacts,
            kinds: [Nip01Event.TEXT_NODE_KIND],
            since:
                (DateTime.now().millisecondsSinceEpoch ~/ 1000) - 60 * 60 * 4,
          ),
        ]);

        List<Nip01Event> events = [];
        feedResponse2.stream.listen((event) {
          developer.log("gotEvent: ${event.content}");
          events.add(event);
        });

        await Future.delayed(const Duration(seconds: 5));
        //developer.log("FEED: ${events.toString()}");

        developer.log('##################################################');
        // developer.log(
        //     "Relay: {relay.url} - {relay.assignedPubkeys.length} - {relay.relayUsefulness}");
        // for (var relay in relayJitManager.connectedRelays) {
        //   developer.log(
        //       "Relay: ${relay.url} - ${relay.assignedPubkeys.length} - ${relay.relayUsefulness.toString()}");
        // }
        // developer
        //     .log('relays count: ${relayJitManager.connectedRelays.length}');
        // developer.log('##################################################');
      }

      test('Leo feed best relays', () async {
        await calculateBestRelaysForNpubContactsFeed(
            "npub1w9llyw8c3qnn7h27u3msjlet8xyjz5phdycr5rz335r2j5hj5a0qvs3tur",
            relayMinCountPerPubKey: 2);
      }, timeout: const Timeout.factor(10));

      test('Fmar feed best relays', () async {
        await calculateBestRelaysForNpubContactsFeed(
            "npub1xpuz4qerklyck9evtg40wgrthq5rce2mumwuuygnxcg6q02lz9ms275ams",
            relayMinCountPerPubKey: 2);
      }, timeout: const Timeout.factor(10));

      test('mikedilger feed best relays', () async {
        await calculateBestRelaysForNpubContactsFeed(
            "npub1acg6thl5psv62405rljzkj8spesceyfz2c32udakc2ak0dmvfeyse9p35c",
            relayMinCountPerPubKey: 2);
      }, timeout: const Timeout.factor(10));

      test('Fiatjaf feed best relays', () async {
        await calculateBestRelaysForNpubContactsFeed(
            "npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6",
            relayMinCountPerPubKey: 2);
      }, timeout: const Timeout.factor(10));

      test('Love is Bitcoin (3k follows) feed best relays', () async {
        await calculateBestRelaysForNpubContactsFeed(
            "npub1kwcatqynqmry9d78a8cpe7d882wu3vmrgcmhvdsayhwqjf7mp25qpqf3xx",
            relayMinCountPerPubKey: 2);
      }, timeout: const Timeout.factor(10));
    },
  );
}
