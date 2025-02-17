// ignore_for_file: camel_case_types

import 'package:ndk/domain_layer/usecases/nwc/consts/bitcoin_network.dart';

import 'nwc_response.dart';

/// Represents the result of a 'get_info' response.
class GetInfoResponse extends NwcResponse {
  final String alias;
  final String color;
  final String pubkey;
  final BitcoinNetwork network;
  final int blockHeight;
  final String blockHash;
  final List<String> methods;
  final List<String> notifications;

  GetInfoResponse(
      {required super.resultType,
      required this.alias,
      required this.color,
      required this.pubkey,
      required this.network,
      required this.blockHeight,
      required this.blockHash,
      required this.methods,
      required this.notifications});

  factory GetInfoResponse.deserialize(Map<String, dynamic> input) {
    if (!input.containsKey('result')) {
      throw Exception('Invalid input');
    }

    Map<String, dynamic> result = input['result'] as Map<String, dynamic>;
    final methodsList = result["methods"] as List;
    final notificationsList = result["notifications"] as List? ?? [];

    List<String> methods =
        methodsList.map((method) => method.toString()).toList();

    List<String> notifications = notificationsList
        .map((notification) => notification.toString())
        .toList();

    return GetInfoResponse(
        resultType: input['result_type'] as String,
        alias: result['alias'] as String,
        color: result['color'] as String,
        pubkey: result['pubkey'] as String,
        network: BitcoinNetwork.fromPlaintext(result['network'] as String),
        blockHeight: result['block_height'] as int,
        blockHash: result['block_hash'] as String,
        methods: methods,
        notifications: notifications);
  }
}
