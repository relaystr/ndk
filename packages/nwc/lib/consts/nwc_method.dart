class NwcMethod {
  final String name;

  const NwcMethod(this.name);

  static const NwcMethod GET_INFO = NwcMethod('get_info');
  static const NwcMethod GET_BALANCE = NwcMethod('get_balance');
  static const NwcMethod PAY_INVOICE = NwcMethod('pay_invoice');
  static const NwcMethod MULTI_PAY_INVOICE = NwcMethod('multi_pay_invoice');
  static const NwcMethod PAY_KEYSEND = NwcMethod('pay_keysend');
  static const NwcMethod MULTI_PAY_KEYSEND = NwcMethod('multi_pay_keysend');
  static const NwcMethod MAKE_INVOICE = NwcMethod('make_invoice');
  static const NwcMethod LOOKUP_INVOICE = NwcMethod('lookup_invoice');
  static const NwcMethod LIST_TRANSACTIONS = NwcMethod('list_transactions');
  static const NwcMethod UNKNOWN = NwcMethod('unknown');

  // Registry to store all methods by their plaintext
  static final Map<String, NwcMethod> _methodsRegistry = {
    PAY_INVOICE.name: PAY_INVOICE,
    MULTI_PAY_INVOICE.name: MULTI_PAY_INVOICE,
    PAY_KEYSEND.name: PAY_KEYSEND,
    MULTI_PAY_KEYSEND.name: MULTI_PAY_KEYSEND,
    MAKE_INVOICE.name: MAKE_INVOICE,
    LOOKUP_INVOICE.name: LOOKUP_INVOICE,
    LIST_TRANSACTIONS.name: LIST_TRANSACTIONS,
    GET_BALANCE.name: GET_BALANCE,
    GET_INFO.name: GET_INFO,
    UNKNOWN.name: UNKNOWN,
  };

  // Factory method to get Method by plaintext
  factory NwcMethod.fromPlaintext(String plaintext) {
    return _methodsRegistry[plaintext] ?? NwcMethod.UNKNOWN;
  }
}
