import 'package:ndk/domain_layer/entities/event_filter.dart';
import 'package:ndk/domain_layer/entities/nip_01_event.dart';

import '../../domain_layer/entities/metadata.dart';
import '../../domain_layer/entities/nip_51_list.dart';
import '../nips/nip25/reactions.dart';

class Nip51MuteEventFilter extends EventFilter {
  Nip51List? _muteList;
  List<String>? _mutedTags;
  TrieTree? trieTree;

  Nip51MuteEventFilter();

  set muteList(Nip51List muteList) {
    _mutedTags = muteList.hashtags
        .map((element) => element.value.trim().toLowerCase())
        .toList();
    List<String> words =
        muteList.words.map((e) => e.value.toLowerCase()).toList();
    List<List<int>> treeWords = List.generate(words.length, (index) {
      var word = words[index];
      return word.codeUnits;
    });
    _muteList = muteList;
    trieTree = buildTrieTree(treeWords, null);
  }

  bool hasMutedWord(String targetStr) {
    return trieTree?.check(targetStr.toLowerCase()) ?? false;
  }

  bool isMutedPubKey(String pubKey) {
    return _muteList?.pubKeys.any((element) => element.value == pubKey) ??
        false;
  }

  bool hasMutedHashtag(Nip01Event event) {
    List<String> tTags = event.tTags;
    return tTags.isNotEmpty &&
        _mutedTags != null &&
        tTags.any((tag) => _mutedTags!.contains(tag));
  }

  @override
  bool filter(Nip01Event event) {
    return (event.kind == Metadata.kKind || !isMutedPubKey(event.pubKey)) &&
        (event.kind == Reaction.kKind || !hasMutedWord(event.content)) &&
        !hasMutedHashtag(event);
  }

  TrieTree buildTrieTree(List<List<int>> words, List<int>? skips) {
    skips ??= [];

    var tree = TrieTree(TrieNode())..skips = skips;

    for (var word in words) {
      tree.root.insertWord(word, skips);
    }

    return tree;
  }
}

class TrieTree {
  TrieNode root;
  List<int>? skips;

  TrieTree(this.root);

  bool check(String targetStr) {
    var target = targetStr.codeUnits;
    var index = 0;
    var length = target.length;
    for (; index < length;) {
      var current = root;
      for (var i = index; i < length; i++) {
        var char = target[i];
        var tmpNode = current.find(char);
        if (tmpNode != null) {
          current = tmpNode;
          if (current.done) {
            return true;
          }
        } else {
          break;
        }
      }
      index++;
    }

    return false;
  }
}

class TrieNode {
  Map<int, TrieNode> children = {};
  bool done;

  TrieNode({
    this.done = false,
  });

  void insertWord(List<int> word, List<int> skips) {
    var current = this;
    for (var char in word) {
      current = current.findOrCreate(char, skips);
    }
    current.done = true;
  }

  TrieNode? find(int char) {
    return children[char];
  }

  TrieNode findOrCreate(int char, List<int> skips) {
    var child = children[char];
    if (child == null) {
      child = TrieNode();

      children[char] = child;
      for (var skip in skips) {
        children[skip] = child;
      }
    }
    return child;
  }
}
