import 'package:http/http.dart' as http;

import 'dart:convert';

class MockCashuHttpClient extends http.BaseClient {
  final Map<String, dynamic> _responses = {};
  final List<http.Request> capturedRequests = [];

  MockCashuHttpClient() {
    _setupDefaultResponses();
  }

  void _setupDefaultResponses() {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    _responses['GET:/v1/info'] = http.Response(
      jsonEncode({
        "name": "testmint1",
        "version": "cdk-mintd/0.10.1",
        "description": "",
        "nuts": {
          "4": {
            "methods": [
              {
                "method": "bolt11",
                "unit": "sat",
                "min_amount": 1,
                "max_amount": 500000,
                "description": true
              }
            ],
            "disabled": false
          },
          "5": {
            "methods": [
              {
                "method": "bolt11",
                "unit": "sat",
                "min_amount": 1,
                "max_amount": 500000
              }
            ],
            "disabled": false
          },
          "7": {"supported": true},
          "8": {"supported": true},
          "9": {"supported": true},
          "10": {"supported": true},
          "11": {"supported": true},
          "12": {"supported": true},
          "14": {"supported": true},
          "15": {
            "methods": [
              {"method": "bolt11", "unit": "sat"},
            ]
          },
          "17": {
            "supported": [
              {
                "method": "bolt11",
                "unit": "sat",
                "commands": [
                  "bolt11_mint_quote",
                  "bolt11_melt_quote",
                  "proof_state"
                ]
              }
            ]
          },
          "19": {
            "ttl": 60,
            "cached_endpoints": [
              {"method": "POST", "path": "/v1/mint/bolt11"},
              {"method": "POST", "path": "/v1/melt/bolt11"},
              {"method": "POST", "path": "/v1/swap"}
            ]
          },
          "20": {"supported": true}
        },
        "motd": "Hello world",
        "time": 1757162808
      }),
      200,
      headers: {'content-type': 'application/json'},
    );

    // Mock keysets response
    _responses['GET:/v1/keysets'] = http.Response(
      jsonEncode({
        "keysets": [
          {
            "id": "00c726786980c4d9",
            "unit": "sat",
            "active": true,
            "input_fee_ppk": 0
          }
        ]
      }),
      200,
      headers: {'content-type': 'application/json'},
    );

    // Mock keys response
    _responses['GET:/v1/keys'] = http.Response(
      jsonEncode({
        "keysets": [
          {
            "id": "00c726786980c4d9",
            "unit": "sat",
            "keys": {
              "1":
                  "02e67dd580169fb31cda6fe475581937a3a04bb0b422c624bfd6eeee1f6da6fa3c",
              "1024":
                  "028fb71ffae7afbb43d04a8992b4ea268b0d9aff0921d0abed85ccd2099821b80a",
              "1048576":
                  "03556358859d99dca7e6672bac4f12afcf88d0feee2c834800e917d0223b4e37a9",
              "1073741824":
                  "031f80815097783a515dbf515578e35542f5675ce92caa158c95db64e68571ad5d",
              "128":
                  "03ac769f6d6d4ca6ef83549bf8535280ff70676f45045df782ac20e80f37f0012f",
              "131072":
                  "03c711b7a810fc4c8bb42f3ae1d2259cd29cde521fbfd1a96053b7828c8b34a22a",
              "134217728":
                  "027e651c25fbcfaf2dc5ef9f6a09286df5d19d07c7c894a2accd2a2a8602f7f6f6",
              "16":
                  "03de6848400b656115c502fcf6bc27266ee372b4e256cb337e10e5ee897380f80a",
              "16384":
                  "03e5ce94bb082f26cb0978f65dab72acababe8f6691a9cf88dbaede223a0221925",
              "16777216":
                  "03572b3fed165a371f54563fadef13f9bc8cfd7841ff200f049a3c57226bd0e0b2",
              "2":
                  "03633147c9a55a7d354ab15960675981e0c879d969643cea7da6889963afb90d3d",
              "2048":
                  "028644efab3ad590188508f7d3c462b57d592932c5a726b9311342003ec52a084b",
              "2097152":
                  "02df9890ef6ecd31146660485a1102979cf6365a80025636ba8c8c1a9a36a0ba89",
              "2147483648":
                  "02cc0f4252dc5f4672b863a261b3f7630bd65bd3201580cfff75de6634807c12b3",
              "256":
                  "03e4b4bb96562a4855a88814a8659eb7f7eab2df7639d7b646086d5dbe3ae0c7e2",
              "262144":
                  "0369d8da14ce6fcd33aa3aff9467b013aad9da5e12515bc6079bebf0da85daea5b",
              "268435456":
                  "03ca1e98639a08c2e3724711bbce00fd6a427c27a9b0b6cf7f327b44918b5c43c6",
              "32":
                  "030f589815a72b4c2fa4fe728e8b38a102228ef1eb490085d92d567d6ec8c97c09",
              "32768":
                  "0353fd1089a6ff7db8c15f82e4c767789e76b0995da1ede24e7243f33b8301d082",
              "33554432":
                  "0247abfe7eddd1f55e6c0f8e01c6160bde9b3fc98ee9413f192817a472e0abfcc8",
              "4":
                  "0393db23532a95b722da09168f39010561babd79c73e63313890ac6fd5e100e6ac",
              "4096":
                  "02718e4fca012601ebb320459fb57607ef9942f901683bf54ab6d6ec2eba2a523d",
              "4194304":
                  "020030f75e5a64e7e09150cba9e2572720504d37d438d00b22b16434c7676617e3",
              "512":
                  "032b95061460afaebdd0d9f3bad6c1d18dbb738b5daacf64a517e131d47133aad1",
              "524288":
                  "02d4ebcf9edec380d52b7190f77d44e6fd7fc195f0f60df656772c74775f2ef653",
              "536870912":
                  "02775c491ed9705b84fc0d1dd3abfec5e75fad5b1109240c67ae655b0024c06d1b",
              "64":
                  "03d3bab9f316f22c6ceebafb73d9506a9d43863c453a2d3bf7940a0b1e8bba0fb9",
              "65536":
                  "03344277ddad3a2cf49c21c5cac9ea620bb24f48fb534abd1539c4a5f3aa620749",
              "67108864":
                  "034824c572029074aa94de30fba1bfaa3e9f090da0d1166888dfd11285f1a7874d",
              "8":
                  "02ce8f0423a31496b3a405ce472a19f270dc526330d767beae8ec43a4812cbe43b",
              "8192":
                  "02e47c542ba5c3664a839e6c5e3968b69916ae9e9387b8eaf973897f4f4ff9de72",
              "8388608":
                  "02c7690d8e9032602cb29f4b0123bf8131dd58f42c0d4f457491b33594181a87c7"
            }
          }
        ]
      }),
      200,
      headers: {'content-type': 'application/json'},
    );

    _responses['GET:/v1/keys/00c726786980c4d9'] = http.Response(
      jsonEncode({
        "keysets": [
          {
            "id": "00c726786980c4d9",
            "unit": "sat",
            "keys": {
              "1":
                  "02e67dd580169fb31cda6fe475581937a3a04bb0b422c624bfd6eeee1f6da6fa3c",
              "1024":
                  "028fb71ffae7afbb43d04a8992b4ea268b0d9aff0921d0abed85ccd2099821b80a",
              "1048576":
                  "03556358859d99dca7e6672bac4f12afcf88d0feee2c834800e917d0223b4e37a9",
              "1073741824":
                  "031f80815097783a515dbf515578e35542f5675ce92caa158c95db64e68571ad5d",
              "128":
                  "03ac769f6d6d4ca6ef83549bf8535280ff70676f45045df782ac20e80f37f0012f",
              "131072":
                  "03c711b7a810fc4c8bb42f3ae1d2259cd29cde521fbfd1a96053b7828c8b34a22a",
              "134217728":
                  "027e651c25fbcfaf2dc5ef9f6a09286df5d19d07c7c894a2accd2a2a8602f7f6f6",
              "16":
                  "03de6848400b656115c502fcf6bc27266ee372b4e256cb337e10e5ee897380f80a",
              "16384":
                  "03e5ce94bb082f26cb0978f65dab72acababe8f6691a9cf88dbaede223a0221925",
              "16777216":
                  "03572b3fed165a371f54563fadef13f9bc8cfd7841ff200f049a3c57226bd0e0b2",
              "2":
                  "03633147c9a55a7d354ab15960675981e0c879d969643cea7da6889963afb90d3d",
              "2048":
                  "028644efab3ad590188508f7d3c462b57d592932c5a726b9311342003ec52a084b",
              "2097152":
                  "02df9890ef6ecd31146660485a1102979cf6365a80025636ba8c8c1a9a36a0ba89",
              "2147483648":
                  "02cc0f4252dc5f4672b863a261b3f7630bd65bd3201580cfff75de6634807c12b3",
              "256":
                  "03e4b4bb96562a4855a88814a8659eb7f7eab2df7639d7b646086d5dbe3ae0c7e2",
              "262144":
                  "0369d8da14ce6fcd33aa3aff9467b013aad9da5e12515bc6079bebf0da85daea5b",
              "268435456":
                  "03ca1e98639a08c2e3724711bbce00fd6a427c27a9b0b6cf7f327b44918b5c43c6",
              "32":
                  "030f589815a72b4c2fa4fe728e8b38a102228ef1eb490085d92d567d6ec8c97c09",
              "32768":
                  "0353fd1089a6ff7db8c15f82e4c767789e76b0995da1ede24e7243f33b8301d082",
              "33554432":
                  "0247abfe7eddd1f55e6c0f8e01c6160bde9b3fc98ee9413f192817a472e0abfcc8",
              "4":
                  "0393db23532a95b722da09168f39010561babd79c73e63313890ac6fd5e100e6ac",
              "4096":
                  "02718e4fca012601ebb320459fb57607ef9942f901683bf54ab6d6ec2eba2a523d",
              "4194304":
                  "020030f75e5a64e7e09150cba9e2572720504d37d438d00b22b16434c7676617e3",
              "512":
                  "032b95061460afaebdd0d9f3bad6c1d18dbb738b5daacf64a517e131d47133aad1",
              "524288":
                  "02d4ebcf9edec380d52b7190f77d44e6fd7fc195f0f60df656772c74775f2ef653",
              "536870912":
                  "02775c491ed9705b84fc0d1dd3abfec5e75fad5b1109240c67ae655b0024c06d1b",
              "64":
                  "03d3bab9f316f22c6ceebafb73d9506a9d43863c453a2d3bf7940a0b1e8bba0fb9",
              "65536":
                  "03344277ddad3a2cf49c21c5cac9ea620bb24f48fb534abd1539c4a5f3aa620749",
              "67108864":
                  "034824c572029074aa94de30fba1bfaa3e9f090da0d1166888dfd11285f1a7874d",
              "8":
                  "02ce8f0423a31496b3a405ce472a19f270dc526330d767beae8ec43a4812cbe43b",
              "8192":
                  "02e47c542ba5c3664a839e6c5e3968b69916ae9e9387b8eaf973897f4f4ff9de72",
              "8388608":
                  "02c7690d8e9032602cb29f4b0123bf8131dd58f42c0d4f457491b33594181a87c7"
            }
          }
        ]
      }),
      200,
      headers: {'content-type': 'application/json'},
    );

    _responses['POST:/v1/mint/quote/bolt11'] = http.Response(
      jsonEncode({
        "quote": "d00e6cbc-04c9-4661-8909-e47c19612bf0",
        "request":
            "lnbc50p1p5tctmqdqqpp5y7jyyyq3ezyu3p4c9dh6qpnjj6znuzrz35ernjjpkmw6lz7y2mxqsp59g4z52329g4z52329g4z52329g4z52329g4z52329g4z52329g4q9qrsgqcqzysl62hzvm9s5nf53gk22v5nqwf9nuy2uh32wn9rfx6grkjh6vr5jmy09mra5cna504azyhkd2ehdel9sm7fm72ns6ws2fk4m8cwc99hdgptq8hv4",
        "amount": 5,
        "unit": "sat",
        "state": "UNPAID",
        "expiry": now + 60
      }),
      200,
      headers: {'content-type': 'application/json'},
    );

    _responses[
            'GET:/v1/mint/quote/bolt11/d00e6cbc-04c9-4661-8909-e47c19612bf0'] =
        http.Response(
      jsonEncode({
        "quote": "d00e6cbc-04c9-4661-8909-e47c19612bf0",
        "request":
            "lnbc50p1p5tctmqdqqpp5y7jyyyq3ezyu3p4c9dh6qpnjj6znuzrz35ernjjpkmw6lz7y2mxqsp59g4z52329g4z52329g4z52329g4z52329g4z52329g4z52329g4q9qrsgqcqzysl62hzvm9s5nf53gk22v5nqwf9nuy2uh32wn9rfx6grkjh6vr5jmy09mra5cna504azyhkd2ehdel9sm7fm72ns6ws2fk4m8cwc99hdgptq8hv4",
        "amount": 5,
        "unit": "sat",
        "state": "PAID",
        "expiry": now + 60
      }),
      200,
      headers: {'content-type': 'application/json'},
    );
    _responses['POST:/v1/mint/bolt11'] = http.Response(
      jsonEncode(
        {"signatures": []},
      ),
      200,
      headers: {'content-type': 'application/json'},
    );
  }

  void setCustomResponse(String method, String path, http.Response response) {
    _responses['$method:$path'] = response;
  }

  void setNetworkError(String method, String path) {
    _responses['$method:$path'] = 'NETWORK_ERROR';
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    capturedRequests.add(request as http.Request);

    final key = '${request.method}:${request.url.path}';

    if (_responses.containsKey(key)) {
      final response = _responses[key];

      if (response == 'NETWORK_ERROR') {
        throw Exception('Network error');
      }

      if (response is http.Response) {
        return http.StreamedResponse(
          Stream.value(utf8.encode(response.body)),
          response.statusCode,
          headers: response.headers,
        );
      }
    }

    // default 404
    return http.StreamedResponse(
      Stream.value(
          utf8.encode(jsonEncode({'error': 'Not found, method: $key'}))),
      404,
      headers: {'content-type': 'application/json'},
    );
  }

  void clearCapturedRequests() {
    capturedRequests.clear();
  }

  http.Request? getLastRequest() {
    return capturedRequests.isNotEmpty ? capturedRequests.last : null;
  }

  List<http.Request> getRequestsForPath(String path) {
    return capturedRequests.where((req) => req.url.path == path).toList();
  }
}
