import 'package:ndk/domain_layer/usecases/nwc/consts/nwc_method.dart';
import 'package:ndk/domain_layer/usecases/nwc/requests/list_transactions.dart';
import 'package:ndk/domain_layer/usecases/nwc/requests/lookup_invoice.dart';
import 'package:ndk/domain_layer/usecases/nwc/requests/make_invoice.dart';
import 'package:ndk/domain_layer/usecases/nwc/requests/multi_pay_invoice.dart';
import 'package:ndk/domain_layer/usecases/nwc/requests/multi_pay_keysend.dart';
import 'package:ndk/domain_layer/usecases/nwc/requests/nwc_request.dart';
import 'package:ndk/domain_layer/usecases/nwc/requests/pay_invoice.dart';
import 'package:ndk/domain_layer/usecases/nwc/requests/pay_keysend.dart';
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

    test('should return ListTransactionsRequest for LIST_TRANSACTIONS', () {
      final map = {'method': NwcMethod.LIST_TRANSACTIONS.name, 'unpaid': true};
      final request = NwcRequest.fromMap(map);
      expect(request, isA<ListTransactionsRequest>());
    });

    test('should return LookupInvoiceRequest for LOOKUP_INVOICE', () {
      final map = {'method': NwcMethod.LOOKUP_INVOICE.name};
      final request = NwcRequest.fromMap(map);
      expect(request, isA<LookupInvoiceRequest>());
    });

    test('should return MakeInvoiceRequest for MAKE_INVOICE', () {
      final map = {
        'method': NwcMethod.MAKE_INVOICE.name,
        'amount': 1000,
        'description': 'Test invoice',
        'expiry': 3600,
      };
      final request = NwcRequest.fromMap(map);
      expect(request, isA<MakeInvoiceRequest>());
      expect((request as MakeInvoiceRequest).amountSat, 1);
      expect(request.description, 'Test invoice');
    });

    test('should return MultiPayInvoiceRequest for MULTI_PAY_INVOICE', () {
      final map = {'method': NwcMethod.MULTI_PAY_INVOICE.name, 'invoices':[{
      'invoice': 'i',
      'amount': 1,
      }]};
      final request = NwcRequest.fromMap(map);
      expect(request, isA<MultiPayInvoiceRequest>());
    });

    test('should return MultiPayKeysendRequest for MULTI_PAY_KEYSEND', () {
      final map = {'method': NwcMethod.MULTI_PAY_KEYSEND.name, 'keysends':[{
        'pubkey': 'p',
        'amount': 1,
        'preimage': 'p',
        'tlv_records':[]
      }]};
      final request = NwcRequest.fromMap(map);
      expect(request, isA<MultiPayKeysendRequest>());
    });

    test('should return PayInvoiceRequest for PAY_INVOICE', () {
      final map = {'method': NwcMethod.PAY_INVOICE.name, 'invoice':''};
      final request = NwcRequest.fromMap(map);
      expect(request, isA<PayInvoiceRequest>());
    });

    test('should return PayKeysendRequest for PAY_KEYSEND', () {
      final map = {'method': NwcMethod.PAY_KEYSEND.name,
        'pubkey': 'p',
        'amount': 1,
        'preimage': 'p',
        'tlv_records':[]
      };
      final request = NwcRequest.fromMap(map);
      expect(request, isA<PayKeysendRequest>());
    });

    // Add more tests for any additional methods in NwcMethod
  });
}
