import '../../entities/contact_list.dart';

/// A convenience view over the kind 3 events of the event store, not a
/// separate authoritative silo.
abstract interface class ContactListStore {
  @Deprecated(
    'Use saveEvent()/saveEvents() with kind 3 events; ContactList is now a convenience view over the generic event cache.',
  )
  Future<void> saveContactList(ContactList contactList);
  @Deprecated(
    'Use saveEvent()/saveEvents() with kind 3 events; ContactList is now a convenience view over the generic event cache.',
  )
  Future<void> saveContactLists(List<ContactList> contactLists);
  Future<ContactList?> loadContactList(String pubKey);
  @Deprecated(
    'Use removeEvents(pubKeys: ..., kinds: [ContactList.kKind]); ContactList is now a convenience view over the generic event cache.',
  )
  Future<void> removeContactList(String pubKey);
  Future<void> removeAllContactLists();
}
