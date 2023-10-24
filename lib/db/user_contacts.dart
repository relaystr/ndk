import 'package:dart_ndk/nips/nip01/helpers.dart';
import 'package:dart_ndk/nips/nip02/contact_list.dart';
import 'package:isar/isar.dart';

part 'user_contacts.g.dart';

@collection
class UserContacts {
  String get id => pubKey;

  String pubKey;

  List<Contact> contacts;

  @ignore
  List<String> get pubKeys => contacts.map((e) => e.pubKey).toList();

  List<String>? followedTags;
  List<String>? followedCommunities;
  List<String>? followedEvents;

  int createdAt;
  int refreshedTimestamp;

  UserContacts(this.pubKey, this.contacts, this.createdAt, this.refreshedTimestamp);

  static UserContacts fromNip02ContactList(Nip02ContactList nip02contactList) {
    List<Contact> contacts = nip02contactList.contacts.map((contact) {
      int idx = nip02contactList.contacts.indexOf(contact);
      String? relay = nip02contactList.contactRelays.length > idx ? nip02contactList.contactRelays[idx] : null;
      if (relay != null && Helpers.isBlank(relay)) {
        relay = null;
      }
      String? petname = nip02contactList.petnames.length > idx ? nip02contactList.petnames[idx] : null;
      if (petname != null && Helpers.isBlank(petname)) {
        petname = null;
      }
      return Contact(contact, relay, petname);
    }).toList();

    return UserContacts(
        nip02contactList.pubKey,
        contacts,
        nip02contactList.createdAt,
        DateTime
            .now()
            .millisecondsSinceEpoch ~/ 1000
    );
  }
}

@embedded
class Contact {
  String pubKey;
  String? petname;
  String? relay;

  Contact(this.pubKey, this.petname, this.relay);
}

