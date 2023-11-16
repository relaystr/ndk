import 'dart:async';

import 'package:dart_ndk/dart_ndk.dart';
import 'package:dart_ndk/models/relay_set.dart';
import 'package:dart_ndk/nips/nip01/bip340.dart';
import 'package:dart_ndk/nips/nip01/event.dart';
import 'package:dart_ndk/nips/nip01/filter.dart';
import 'package:dart_ndk/nips/nip01/helpers.dart';
import 'package:dart_ndk/nips/nip01/key_pair.dart';
import 'package:dart_ndk/nips/nip02/contact_list.dart';
import 'package:dart_ndk/nips/nip65/nip65.dart';
import 'package:dart_ndk/nips/nip65/read_write_marker.dart';
import 'package:dart_ndk/read_write.dart';
import 'package:dart_ndk/relay_stats.dart';
import 'package:flutter_test/flutter_test.dart';

import '../mocks/mock_relay.dart';

void main() async {
  test('stats', () async {
    RelayStats stats = RelayStats();
    expect(0, stats.getTotalEventsRead());
    expect(0, stats.getTotalBytesRead());
  });
}
