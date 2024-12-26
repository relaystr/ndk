import 'package:ndk/domain_layer/usecases/nwc/consts/nwc_method.dart';
import 'package:ndk/domain_layer/usecases/nwc/requests/get_info.dart';
import 'package:ndk/domain_layer/usecases/nwc/requests/make_invoice.dart';
import 'package:ndk/domain_layer/usecases/nwc/requests/nwc_request.dart';
import 'package:test/test.dart';

void main() {
  group('NwcRequest', () {

    // KeyPair app = Bip340.generatePrivateKey();
    // KeyPair wallet = Bip340.generatePrivateKey();
    //
    // test('fromEvent should correctly parse a valid event', () {
    //   GetInfoRequest getInfoRequest = GetInfoRequest();
    //   var json = getInfoRequest.toMap();
    //   var content = jsonEncode(json);
    //
    //   var encrypted = Nip04.encrypt(app.privateKey!, app.publicKey, content);
    //   // Mock data
    //   final event = Nip01Event(
    //     pubKey: wallet.publicKey,
    //     content: encrypted,
    //     createdAt: DateTime.now().millisecondsSinceEpoch,
    //     kind: NwcKind.REQUEST.value,
    //     tags: [],
    //   );
    //
    //   final request = NwcRequest.fromEvent(event, app.privateKey!);
    //
    //   expect(request, isA<GetInfoRequest>());
    // });

    test('fromMap should return correct request type for GET_INFO', () {
      final map = {
        'method': 'get_info',
      };

      final request = NwcRequest.fromMap(map);

      expect(request, isA<GetInfoRequest>());
    });

    test('fromMap should return correct request type for MAKE_INVOICE', () {
      final map = {
        'method': 'make_invoice',
        'amount': 1000,
        'description': 'Test invoice',
        'description_hash': null,
        'expiry': 3600,
      };

      final request = NwcRequest.fromMap(map);

      expect(request, isA<MakeInvoiceRequest>());
      expect((request as MakeInvoiceRequest).amountSat, 1);
      expect(request.description, 'Test invoice');
    });

    test('fromMap should throw exception for unknown method', () {
      final map = {
        'method': 'UNKNOWN_METHOD',
      };

      expect(() => NwcRequest.fromMap(map), throwsException);
    });

    test('toMap should correctly convert NwcRequest to map', () {
      final request = NwcRequest(method: NwcMethod.GET_INFO);

      final map = request.toMap();

      expect(map['method'], 'get_info');
    });

    // Add more tests for other methods and edge cases
  });
}
