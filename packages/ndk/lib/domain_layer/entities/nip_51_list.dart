import 'dart:convert';

import '../../shared/helpers/list_casting.dart';
import '../../shared/logger/logger.dart';
import '../../shared/nips/nip01/helpers.dart';
import '../repositories/event_signer.dart';
import 'nip_01_event.dart';

class Nip51List {
  static const int kMute = 10000;
  static const int kPin = 10001;
  static const int kBookmarks = 10003;
  static const int kCommunities = 10004;
  static const int kPublicChats = 10005;
  static const int kBlockedRelays = 10006;
  static const int kSearchRelays = 10007;
  static const int kInterests = 10015;
  static const int kEmojis = 10030;

  static const int kFollowSet = 30000;
  static const int kRelaySet = 30002;
  static const int kBookmarksSet = 30003;
  static const int kCurationSet = 30004;
  static const int kCurationVideoSet = 30005;
  static const int kKindMuteSet = 30007;
  static const int kInterestsSet = 30015;
  static const int kEmojisSet = 30030;
  static const int kReleaseArtifactSet = 30063;
  static const int kAppCurationSet = 30267;
  static const int kCalendar = 31924;
  static const int kStarterPacks = 39089;
  static const int kStarterPacksMedia = 39092;

  static const String kRelay = "relay";
  static const String kPubkey = "p";
  static const String kHashtag = "t";
  static const String kWord = "word";
  static const String kThread = "e";
  static const String kResource = "r";
  static const String kEmoji = "emoji";
  static const String kA = "a";

  static const List<int> kPossibleKinds = [
    kMute,
    kPin,
    kBookmarks,
    kCommunities,
    kPublicChats,
    kBlockedRelays,
    kSearchRelays,
    kInterests,
    kEmojis,
    kFollowSet,
    kRelaySet,
    kBookmarksSet,
    kCurationSet,
    kCurationVideoSet,
    kKindMuteSet,
    kInterestsSet,
    kEmojisSet,
    kReleaseArtifactSet,
    kAppCurationSet,
    kCalendar,
    kStarterPacks,
    kStarterPacksMedia,
  ];

  static const List<String> kPossibleTags = [
    kRelay,
    kPubkey,
    kHashtag,
    kWord,
    kThread,
    kResource,
    kEmoji,
    kA
  ];

  late String id;
  late String pubKey;
  late int kind;

  List<Nip51ListElement> elements = [];

  List<Nip51ListElement> byTag(String tag) =>
      elements.where((element) => element.tag == tag).toList();

  List<Nip51ListElement> get relays => byTag(kRelay);
  List<Nip51ListElement> get pubKeys => byTag(kPubkey);
  List<Nip51ListElement> get hashtags => byTag(kHashtag);
  List<Nip51ListElement> get words => byTag(kWord);
  List<Nip51ListElement> get threads => byTag(kThread);

  List<String> get publicRelays =>
      relays.where((element) => !element.private).map((e) => e.value).toList();
  List<String> get privateRelays =>
      relays.where((element) => !element.private).map((e) => e.value).toList();

  set privateRelays(List<String> list) {
    elements.removeWhere((element) => element.tag == kRelay && element.private);
    elements.addAll(list.map(
        (url) => Nip51ListElement(tag: kRelay, value: url, private: true)));
  }

  set publicRelays(List<String> list) {
    elements
        .removeWhere((element) => element.tag == kRelay && !element.private);
    elements.addAll(list.map(
        (url) => Nip51ListElement(tag: kRelay, value: url, private: false)));
  }

  late int createdAt;

  @override
  // coverage:ignore-start
  String toString() {
    return 'Nip51List { $kind}';
  }
  // coverage:ignore-end

  String get displayTitle {
    if (kind == Nip51List.kSearchRelays) {
      return "Search";
    }
    if (kind == Nip51List.kBlockedRelays) {
      return "Blocked";
    }
    if (kind == Nip51List.kMute) {
      return "Mute";
    }
    return "kind $kind";
  }

  List<String> get allRelays => relays.map((e) => e.value).toList();

  Nip51List(
      {required this.pubKey,
      required this.kind,
      required this.createdAt,
      required this.elements});

  static Future<Nip51List> fromEvent(
      Nip01Event event, EventSigner? signer) async {
    // if (event.kind == Nip51List.SEARCH_RELAYS || event.kind == Nip51List.BLOCKED_RELAYS) {
    //   privateRelays = [];
    //   publicRelays = [];
    // }
    Nip51List list = Nip51List(
        pubKey: event.pubKey,
        kind: event.kind,
        createdAt: event.createdAt,
        elements: []);
    list.id = event.id;

    list.parseTags(event.tags, private: false);

    if (Helpers.isNotBlank(event.content) &&
        signer != null &&
        signer.canSign()) {
      try {
        var json = await signer.decrypt(event.content, signer.getPublicKey());
        List<dynamic> tags = jsonDecode(json ?? '');
        list.parseTags(tags, private: true);
      } catch (e) {
        Logger.log.d(e);
      }
    }
    return list;
  }

  void parseTags(List tags, {required bool private}) {
    for (var tag in tags) {
      if (tag is! List<dynamic>) continue;
      final length = tag.length;
      if (length <= 1) continue;
      final tagName = tag[0];
      final value = tag[1];
      if (kPossibleTags.contains(tagName)) {
        elements.add(
            Nip51ListElement(tag: tagName, value: value, private: private));
      }
    }
  }

  Future<Nip01Event> toEvent(EventSigner? signer) async {
    String content = "";
    List<Nip51ListElement> privateElements =
        elements.where((element) => element.private).toList();
    if (privateElements.isNotEmpty && signer != null) {
      String json = jsonEncode(privateElements
          .map((element) => [element.tag, element.value])
          .toList());
      content = await signer.encrypt(json, signer.getPublicKey()) ?? '';
    }
    Nip01Event event = Nip01Event(
      pubKey: pubKey,
      kind: kind,
      tags: elements
          .where((element) => !element.private)
          .map((element) => [element.tag, element.value])
          .toList(),
      content: content,
      createdAt: createdAt,
    );
    return event;
  }

  void addRelay(String relayUrl, bool private) {
    elements
        .add(Nip51ListElement(tag: kRelay, value: relayUrl, private: private));
  }

  void addElement(String tag, String value, bool private) {
    elements.add(Nip51ListElement(tag: tag, value: value, private: private));
  }

  void removeRelay(String relayUrl) {
    elements.removeWhere(
        (element) => element.tag == kRelay && element.value == relayUrl);
  }

  void removeElement(String tag, String value) {
    elements
        .removeWhere((element) => element.tag == tag && element.value == value);
  }
}

class Nip51ListElement {
  bool private;
  String tag;
  String value;

  Nip51ListElement(
      {required this.tag, required this.value, required this.private});
}

class Nip51Set extends Nip51List {
  late String name;
  String? title;
  String? description;
  String? image;

  @override
  // coverage:ignore-start
  String toString() {
    return 'Nip51Set { $name}';
  }
  // coverage:ignore-end

  Nip51Set({
    required super.pubKey,
    required this.name,
    required super.createdAt,
    required super.elements,
    required super.kind,
    this.title,
    this.description,
    this.image,
  }) : super();

  static Future<Nip51Set?> fromEvent(
    Nip01Event event,
    EventSigner? signer,
  ) async {
    String? name = event.getDtag();
    if (name == null) {
      return null;
    }
    Nip51Set set = Nip51Set(
      pubKey: event.pubKey,
      name: name,
      createdAt: event.createdAt,
      kind: event.kind,
      elements: [],
    );
    set.id = event.id;
    if (Helpers.isNotBlank(event.content) &&
        signer != null &&
        signer.canSign()) {
      try {
        var json = await signer.decrypt(event.content, signer.getPublicKey());
        List<dynamic> tags = jsonDecode(json ?? '');
        set.parseTags(tags, private: true);
        set.parseSetTags(tags);
      } catch (e) {
        set.name = "<invalid encrypted content>";
        Logger.log.d(e);
      }
    } else {
      set.parseTags(event.tags, private: false);
      set.parseSetTags(event.tags);
    }
    return set;
  }

  @override
  Future<Nip01Event> toEvent(EventSigner? signer) async {
    Nip01Event event = await super.toEvent(signer);
    List<dynamic> tags = [
      ["d", name]
    ];
    if (Helpers.isNotBlank(description)) {
      tags.add(["description", description]);
    }
    if (Helpers.isNotBlank(image)) {
      tags.add(["image", image]);
    }
    if (Helpers.isNotBlank(title)) {
      tags.add(["title", title]);
    }

    tags.addAll(event.tags);

    final copy = event.copyWith(
      pubKey: event.pubKey,
      kind: event.kind,
      tags: castToListOfListOfString(tags),
      content: event.content,
      createdAt: event.createdAt,
    );

    return copy;
  }

  void parseSetTags(List tags) {
    for (var tag in tags) {
      if (tag is! List<dynamic>) continue;
      final length = tag.length;
      if (length <= 1) continue;
      final tagName = tag[0];
      final value = tag[1];
      if (tagName == "d") {
        name = value;
        continue;
      }
      if (tagName == "title") {
        title = value;
        continue;
      }
      if (tagName == "description") {
        description = value;
        continue;
      }
      if (tagName == "image") {
        image = value;
        continue;
      }
    }
  }
}
